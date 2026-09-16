// Canonical SoC (closed system for perf benchmarking and integration).
//
// Topology (single convergence target):
//
//   dual-issue RV32 cores
//     |-- imem0/imem1 -> private L1I x2 per core
//     |-- dmem        -> private WB-MSI L1D per core -- MSI hub (coherence)
//     |-- L1 fabric (shared_interconnect, 3*N -> 1)
//     |-- shared L2 (blocking, 16 KiB)
//     |-- MMIO router: 0x8000_0000/32B -> GPU AXI4-Lite ctrl, rest -> CPU mem
//     |-- DRAM arbiter (shared_interconnect, CPU + GPU -> 1)
//     |-- banked DRAM (NUM_BANKS striped, per-bank latency)
//   GPU data path: rect engine AXI4 bursts -> axi4_to_mem -> DRAM arbiter
//   GPU ctrl path: AXI4-Lite MMIO window (uncached)
//
// Address map (32-bit):
//   0x0000_0000 - 0x7FFF_FFFF : cacheable DRAM (L1/L2 cacheable)
//   0x8000_0000 - 0x8000_001F : GPU ctrl registers, uncached (AXI4-Lite)
//   FB lives in DRAM (e.g. 0x0010_0000); GPU AXI bursts hit DRAM directly.
//
// Perf pieces kept: dual issue, private L1s, shared L2, MSI coherence,
// GPU AXI bursts, banked DRAM. Legacy single-issue / write-through /
// nonblocking roots remain under rtl/soc/variants/ for regression only.
//
// Triangle rasterizer is intentionally out of scope here; the rect path
// (gpu.sv + raster/rect-rasterizer stub + memory/axi4-span-writer) is the
// current fill engine and will be reconciled later.
module soc #(
    parameter int unsigned NUM_CORES = 2,
    parameter logic [31:0] RESET_PC = 32'h0000_0000,
    parameter int unsigned L1_BYTES = 1024,
    parameter int unsigned L2_BYTES = 16384,
    parameter int unsigned LINE_BYTES = 16,
    parameter int unsigned DRAM_BYTES = 65536,
    parameter int unsigned NUM_DRAM_BANKS = 4,
    parameter int unsigned DRAM_READ_LATENCY = 8,
    parameter int unsigned DRAM_WRITE_LATENCY = 4,
    parameter logic [31:0] GPU_BASE = 32'h8000_0000,
    parameter int unsigned GPU_BYTES = 32
) (
    input logic clk,
    input logic rst_n,
    input logic [NUM_CORES-1:0] irq,
    output logic [NUM_CORES-1:0] halted,
    output logic [NUM_CORES-1:0] trap_illegal,
    output logic [NUM_CORES-1:0] interrupt_taken,
    output logic [NUM_CORES-1:0] retire_valid0,
    output logic [NUM_CORES-1:0] retire_valid1,
    output logic [31:0] retire_pc0 [NUM_CORES],
    output logic [31:0] retire_pc1 [NUM_CORES],
    output logic [31:0] retire_instr0 [NUM_CORES],
    output logic [31:0] retire_instr1 [NUM_CORES],
    output logic [4:0] retire_rd0 [NUM_CORES],
    output logic [4:0] retire_rd1 [NUM_CORES],
    output logic [31:0] retire_data0 [NUM_CORES],
    output logic [31:0] retire_data1 [NUM_CORES],
    output logic [63:0] cycle_count [NUM_CORES],
    output logic [63:0] retired_count [NUM_CORES],
    output logic gpu_busy,
    output logic gpu_done,
    output logic gpu_error
);
  localparam int unsigned MASTERS_PER_CORE = 3;
  localparam int unsigned NUM_L1_MASTERS = MASTERS_PER_CORE * NUM_CORES;

  // Core <-> L1 ports.
  mem_if core_imem0 [NUM_CORES](clk, rst_n);
  mem_if core_imem1 [NUM_CORES](clk, rst_n);
  mem_if core_dmem [NUM_CORES](clk, rst_n);

  // L1 -> L1 fabric -> L2.
  mem_if l1_fabric [NUM_L1_MASTERS](clk, rst_n);
  mem_if l2_port [1](clk, rst_n);
  mem_if l2_out (clk, rst_n);

  // L2 -> MMIO router -> {NoC/DRAM path, GPU ctrl}.
  mem_if cpu_mem (clk, rst_n);
  axi4_lite_if gpu_ctrl (clk, rst_n);

  // GPU data path: AXI4 bursts -> mem_if -> DRAM arbiter.
  axi4_if gpu_data_axi (clk, rst_n);
  mem_if gpu_mem (clk, rst_n);

  // DRAM arbiter -> banked DRAM.
  mem_if dram_merge [2](clk, rst_n);
  mem_if dram_noc_slave [1](clk, rst_n);

  msi_coherence_if #(.LINE_W(LINE_BYTES*8)) coh [NUM_CORES](clk, rst_n);

  generate
    for (genvar c = 0; c < NUM_CORES; c++) begin : g_core
      dual_issue_rv32i_core #(.RESET_PC(RESET_PC)) core (
          .clk(clk), .rst_n(rst_n), .irq(irq[c]),
          .imem0(core_imem0[c]), .imem1(core_imem1[c]), .dmem(core_dmem[c]),
          .halted(halted[c]), .trap_illegal(trap_illegal[c]),
          .interrupt_taken(interrupt_taken[c]),
          .retire_valid0(retire_valid0[c]), .retire_pc0(retire_pc0[c]),
          .retire_instr0(retire_instr0[c]), .retire_rd0(retire_rd0[c]),
          .retire_data0(retire_data0[c]),
          .retire_valid1(retire_valid1[c]), .retire_pc1(retire_pc1[c]),
          .retire_instr1(retire_instr1[c]), .retire_rd1(retire_rd1[c]),
          .retire_data1(retire_data1[c]),
          .cycle_count(cycle_count[c]), .retired_count(retired_count[c]));

      l1i_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) i0 (
          .cpu(core_imem0[c]), .memory(l1_fabric[MASTERS_PER_CORE*c]));
      l1i_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) i1 (
          .cpu(core_imem1[c]), .memory(l1_fabric[MASTERS_PER_CORE*c+1]));
      wb_msi_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) d0 (
          .cpu(core_dmem[c]), .memory(l1_fabric[MASTERS_PER_CORE*c+2]),
          .coherence(coh[c]));
    end
  endgenerate

  msi_coherence_hub #(.NUM_CACHES(NUM_CORES), .LINE_BYTES(LINE_BYTES)) hub (
      .clk(clk), .rst_n(rst_n), .cache_port(coh));

  shared_interconnect #(.NUM_MASTERS(NUM_L1_MASTERS), .NUM_SLAVES(1)) l1_fabric_i (
      .clk(clk), .rst_n(rst_n), .master_port(l1_fabric), .slave_port(l2_port));

  l2_cache #(.CACHE_BYTES(L2_BYTES), .LINE_BYTES(LINE_BYTES)) l2 (
      .upstream(l2_port[0]), .memory(l2_out));

  mem_gpu_mmio_router #(.GPU_BASE(GPU_BASE), .GPU_BYTES(GPU_BYTES)) mmio (
      .upstream(l2_out), .memory(cpu_mem), .gpu_ctrl(gpu_ctrl));

  // GPU: AXI4-Lite ctrl (MMIO) + AXI4 burst data (via bridge to DRAM).
  primitive_gpu_2d gpu (
      .ctrl(gpu_ctrl), .data_axi(gpu_data_axi),
      .busy(gpu_busy), .done(gpu_done), .error(gpu_error));

  axi4_to_mem gpu_bridge (.axi(gpu_data_axi), .mem(gpu_mem));

  // NoC = address-routed DRAM arbiter: CPU path + GPU burst path -> DRAM.
  // (MMIO is already split off by the router above; the NoC is the DRAM
  //  data plane. noc_fabric stays the generic mem_if router for reuse.)
  assign dram_merge[0].req_valid = cpu_mem.req_valid;
  assign dram_merge[0].req_addr  = cpu_mem.req_addr;
  assign dram_merge[0].req_write = cpu_mem.req_write;
  assign dram_merge[0].req_wdata = cpu_mem.req_wdata;
  assign dram_merge[0].req_be    = cpu_mem.req_be;
  assign cpu_mem.req_ready = dram_merge[0].req_ready;
  assign cpu_mem.rsp_valid = dram_merge[0].rsp_valid;
  assign cpu_mem.rsp_rdata = dram_merge[0].rsp_rdata;
  assign cpu_mem.rsp_error = dram_merge[0].rsp_error;
  assign dram_merge[0].rsp_ready = cpu_mem.rsp_ready;

  assign dram_merge[1].req_valid = gpu_mem.req_valid;
  assign dram_merge[1].req_addr  = gpu_mem.req_addr;
  assign dram_merge[1].req_write = gpu_mem.req_write;
  assign dram_merge[1].req_wdata = gpu_mem.req_wdata;
  assign dram_merge[1].req_be    = gpu_mem.req_be;
  assign gpu_mem.req_ready = dram_merge[1].req_ready;
  assign gpu_mem.rsp_valid = dram_merge[1].rsp_valid;
  assign gpu_mem.rsp_rdata = dram_merge[1].rsp_rdata;
  assign gpu_mem.rsp_error = dram_merge[1].rsp_error;
  assign dram_merge[1].rsp_ready = gpu_mem.rsp_ready;

  noc_fabric #(.NUM_MASTERS(2), .NUM_SLAVES(1)) dram_noc (
      .clk(clk), .rst_n(rst_n),
      .master_port(dram_merge), .slave_port(dram_noc_slave));

  banked_dram #(
      .MEM_BYTES(DRAM_BYTES), .NUM_BANKS(NUM_DRAM_BANKS),
      .READ_LATENCY(DRAM_READ_LATENCY), .WRITE_LATENCY(DRAM_WRITE_LATENCY)
  ) dram (.bus(dram_noc_slave[0]));

`ifndef SYNTHESIS
  initial assert (NUM_CORES > 0)
    else $fatal(1, "soc requires NUM_CORES > 0");
`endif
endmodule : soc
