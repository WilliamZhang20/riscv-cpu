// Phase 4 composition root: private blocking L1Is plus private write-back MSI
// L1Ds. The legacy multicore_cpu remains available for regression comparison.
module multicore_cpu_wb_msi #(
    parameter int unsigned NUM_CORES=2,
    parameter logic [31:0] RESET_PC=32'h0,
    parameter int unsigned L1_BYTES=1024,
    parameter int unsigned LINE_BYTES=16
) (
    input logic clk, input logic rst_n, mem_if.master memory,
    input logic [NUM_CORES-1:0] irq,
    output logic [NUM_CORES-1:0] halted, output logic [NUM_CORES-1:0] trap_illegal,
    output logic [NUM_CORES-1:0] interrupt_taken, output logic [NUM_CORES-1:0] retire,
    output logic [31:0] retire_pc[NUM_CORES], output logic [31:0] retire_instr[NUM_CORES],
    output logic [63:0] cycle_count[NUM_CORES], output logic [63:0] retired_count[NUM_CORES],
    output logic [63:0] imem_stall_count[NUM_CORES], output logic [63:0] dmem_stall_count[NUM_CORES]
);
  localparam int unsigned MASTERS=2*NUM_CORES;
  mem_if imem[NUM_CORES](clk,rst_n), dmem[NUM_CORES](clk,rst_n);
  mem_if fabric[MASTERS](clk,rst_n);
  mem_if external[1](clk,rst_n);
  msi_coherence_if #(.LINE_W(LINE_BYTES*8)) coh[NUM_CORES](clk,rst_n);
  generate for (genvar c=0;c<NUM_CORES;c++) begin : g
    cpu_core #(.RESET_PC(RESET_PC)) core(
      .clk(clk),.rst_n(rst_n),.irq(irq[c]),.imem(imem[c]),.dmem(dmem[c]),
      .halted(halted[c]),.trap_illegal(trap_illegal[c]),.interrupt_taken(interrupt_taken[c]),
      .retire(retire[c]),.retire_pc(retire_pc[c]),.retire_instr(retire_instr[c]),
      .cycle_count(cycle_count[c]),.retired_count(retired_count[c]),
      .imem_stall_count(imem_stall_count[c]),.dmem_stall_count(dmem_stall_count[c]));
    l1i_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) ic(.cpu(imem[c]),.memory(fabric[2*c]));
    wb_msi_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) dc(
      .cpu(dmem[c]),.memory(fabric[2*c+1]),.coherence(coh[c]));
  end endgenerate
  msi_coherence_hub #(.NUM_CACHES(NUM_CORES),.LINE_BYTES(LINE_BYTES)) hub(
    .clk(clk),.rst_n(rst_n),.cache_port(coh));
  shared_interconnect #(.NUM_MASTERS(MASTERS),.NUM_SLAVES(1)) fabric_i(
    .clk(clk),.rst_n(rst_n),.master_port(fabric),.slave_port(external));
  assign memory.req_valid=external[0].req_valid; assign memory.req_addr=external[0].req_addr;
  assign memory.req_write=external[0].req_write; assign memory.req_wdata=external[0].req_wdata; assign memory.req_be=external[0].req_be;
  assign external[0].req_ready=memory.req_ready; assign external[0].rsp_valid=memory.rsp_valid;
  assign external[0].rsp_rdata=memory.rsp_rdata; assign external[0].rsp_error=memory.rsp_error;
  assign memory.rsp_ready=external[0].rsp_ready;
endmodule : multicore_cpu_wb_msi
