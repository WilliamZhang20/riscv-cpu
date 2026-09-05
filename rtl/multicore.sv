// Parameterized multicore CPU subsystem: private L1I/L1D per core, one
// coherent invalidation hub, shared interconnect, and shared L2.
module multicore_cpu #(parameter int unsigned NUM_CORES = 2,
    parameter logic [31:0] RESET_PC = 32'h0000_0000,
    parameter int unsigned L1_BYTES = 1024, parameter int unsigned L2_BYTES = 16384,
    parameter int unsigned LINE_BYTES = 16
) (
    input logic clk, input logic rst_n, mem_if.master memory,
    output logic [NUM_CORES-1:0] halted, output logic [NUM_CORES-1:0] trap_illegal,
    output logic [NUM_CORES-1:0] retire, output logic [31:0] retire_pc [NUM_CORES],
    output logic [31:0] retire_instr [NUM_CORES]
);

  localparam int unsigned NUM_MASTERS = 2 * NUM_CORES;
  mem_if core_imem [NUM_CORES](clk, rst_n); mem_if core_dmem [NUM_CORES](clk, rst_n);
  mem_if fabric_master [NUM_MASTERS](clk, rst_n); mem_if l2_port [1](clk, rst_n);
  coherence_if l1d_coherence [NUM_CORES](clk, rst_n);

  generate for (genvar c=0;c<NUM_CORES;c++) begin : g_core
    cpu_core #(.RESET_PC(RESET_PC)) u_core (.clk(clk),.rst_n(rst_n),.imem(core_imem[c]),.dmem(core_dmem[c]),.halted(halted[c]),.trap_illegal(trap_illegal[c]),.retire(retire[c]),.retire_pc(retire_pc[c]),.retire_instr(retire_instr[c]));
    l1i_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) u_l1i (.cpu(core_imem[c]),.memory(fabric_master[2*c]));
    l1d_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) u_l1d (.cpu(core_dmem[c]),.memory(fabric_master[2*c+1]),.coherence(l1d_coherence[c]));
  end 
  endgenerate

  coherence_hub #(.NUM_CACHES(NUM_CORES),.LINE_BYTES(LINE_BYTES)) u_coherence (.clk(clk),.rst_n(rst_n),.cache_port(l1d_coherence));
  shared_interconnect #(.NUM_MASTERS(NUM_MASTERS),.NUM_SLAVES(1)) u_interconnect (.clk(clk),.rst_n(rst_n),.master_port(fabric_master),.slave_port(l2_port));
  l2_cache #(.CACHE_BYTES(L2_BYTES),.LINE_BYTES(LINE_BYTES)) u_l2 (.upstream(l2_port[0]),.memory(memory));
  
`ifndef SYNTHESIS
  initial assert (NUM_CORES > 0) else $fatal(1,"multicore_cpu requires NUM_CORES > 0");
`endif

endmodule : multicore_cpu