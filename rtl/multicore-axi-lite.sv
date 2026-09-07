// External-memory wrapper for multicore_cpu.
// The CPU subsystem keeps mem_if internally; this is the FPGA/SoC AXI boundary.
module multicore_cpu_axi_lite #(
    parameter int unsigned NUM_CORES = 2,
    parameter logic [31:0] RESET_PC = 32'h0000_0000,
    parameter int unsigned L1_BYTES = 1024,
    parameter int unsigned L2_BYTES = 16384,
    parameter int unsigned LINE_BYTES = 16
) (
    input logic clk, input logic rst_n,
    input logic [NUM_CORES-1:0] irq,
    output logic [NUM_CORES-1:0] halted,
    output logic [NUM_CORES-1:0] trap_illegal,
    output logic [NUM_CORES-1:0] interrupt_taken,
    output logic [NUM_CORES-1:0] retire,
    output logic [31:0] retire_pc [NUM_CORES],
    output logic [31:0] retire_instr [NUM_CORES],
    output logic [63:0] cycle_count [NUM_CORES],
    output logic [63:0] retired_count [NUM_CORES],
    output logic [63:0] imem_stall_count [NUM_CORES],
    output logic [63:0] dmem_stall_count [NUM_CORES],
    axi4_lite_if.master axi_memory
);
  mem_if memory(clk, rst_n);
  multicore_cpu #(
      .NUM_CORES(NUM_CORES), .RESET_PC(RESET_PC), .L1_BYTES(L1_BYTES),
      .L2_BYTES(L2_BYTES), .LINE_BYTES(LINE_BYTES)
  ) u_cpu (
      .clk(clk), .rst_n(rst_n), .memory(memory), .irq(irq),
      .halted(halted), .trap_illegal(trap_illegal),
      .interrupt_taken(interrupt_taken), .retire(retire),
      .retire_pc(retire_pc), .retire_instr(retire_instr),
      .cycle_count(cycle_count), .retired_count(retired_count),
      .imem_stall_count(imem_stall_count), .dmem_stall_count(dmem_stall_count)
  );
  mem_to_axi_lite u_memory_bridge(.upstream(memory), .axi(axi_memory));
endmodule : multicore_cpu_axi_lite
