// Multicore composition root using the full two-wide RV32I core.
//
// Each core has two private instruction-cache paths because the dual frontend
// can request PC and PC+4 independently.  The data path uses the existing
// write-through L1D/coherence hub, and all three cache ports share the same L2
// and external memory fabric.
module multicore_cpu_dual_issue #(
    parameter int unsigned NUM_CORES = 1,
    parameter logic [31:0] RESET_PC = 32'h0,
    parameter int unsigned L1_BYTES = 1024,
    parameter int unsigned L2_BYTES = 16384,
    parameter int unsigned LINE_BYTES = 16
) (
    input logic clk, input logic rst_n,
    input logic [NUM_CORES-1:0] irq,
    mem_if.master memory,
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
    output logic [63:0] retired_count [NUM_CORES]
);
  localparam int unsigned MASTERS_PER_CORE = 3;
  localparam int unsigned NUM_MASTERS = MASTERS_PER_CORE * NUM_CORES;

  mem_if core_imem0 [NUM_CORES](clk, rst_n);
  mem_if core_imem1 [NUM_CORES](clk, rst_n);
  mem_if core_dmem  [NUM_CORES](clk, rst_n);
  mem_if fabric [NUM_MASTERS](clk, rst_n);
  mem_if l2_port [1](clk, rst_n);
  coherence_if coherence [NUM_CORES](clk, rst_n);

  generate
    for (genvar c = 0; c < NUM_CORES; c++) begin : g_core
      dual_issue_rv32i_core #(.RESET_PC(RESET_PC)) core (
          .clk(clk), .rst_n(rst_n), .irq(irq[c]),
          .imem0(core_imem0[c]), .imem1(core_imem1[c]),
          .dmem(core_dmem[c]), .halted(halted[c]),
          .trap_illegal(trap_illegal[c]), .interrupt_taken(interrupt_taken[c]),
          .retire_valid0(retire_valid0[c]), .retire_pc0(retire_pc0[c]),
          .retire_instr0(retire_instr0[c]), .retire_rd0(retire_rd0[c]),
          .retire_data0(retire_data0[c]), .retire_valid1(retire_valid1[c]),
          .retire_pc1(retire_pc1[c]), .retire_instr1(retire_instr1[c]),
          .retire_rd1(retire_rd1[c]), .retire_data1(retire_data1[c]),
          .cycle_count(cycle_count[c]), .retired_count(retired_count[c]));

      l1i_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) i0 (
          .cpu(core_imem0[c]), .memory(fabric[MASTERS_PER_CORE*c]));
      l1i_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) i1 (
          .cpu(core_imem1[c]), .memory(fabric[MASTERS_PER_CORE*c+1]));
      l1d_cache #(.CACHE_BYTES(L1_BYTES), .LINE_BYTES(LINE_BYTES)) d0 (
          .cpu(core_dmem[c]), .memory(fabric[MASTERS_PER_CORE*c+2]),
          .coherence(coherence[c]));
    end
  endgenerate

  coherence_hub #(.NUM_CACHES(NUM_CORES), .LINE_BYTES(LINE_BYTES)) hub (
      .clk(clk), .rst_n(rst_n), .cache_port(coherence));
  shared_interconnect #(.NUM_MASTERS(NUM_MASTERS), .NUM_SLAVES(1)) fabric_i (
      .clk(clk), .rst_n(rst_n), .master_port(fabric), .slave_port(l2_port));
  l2_cache #(.CACHE_BYTES(L2_BYTES), .LINE_BYTES(LINE_BYTES)) l2 (
      .upstream(l2_port[0]), .memory(memory));

`ifndef SYNTHESIS
  initial assert (NUM_CORES > 0)
    else $fatal(1, "multicore_cpu_dual_issue requires NUM_CORES > 0");
`endif
endmodule : multicore_cpu_dual_issue
