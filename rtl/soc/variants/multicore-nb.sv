// Phase 3 composition root: legacy single-issue cores drive tagged nonblocking
// private data caches through compatibility bridges.
module multicore_cpu_nb #(
    parameter int unsigned NUM_CORES=2,
    parameter logic [31:0] RESET_PC=32'h0,
    parameter int unsigned L1_BYTES=1024,
    parameter int unsigned LINE_BYTES=16
) (
    input logic clk,input logic rst_n,mem_if.master memory,
    input logic [NUM_CORES-1:0] irq,
    output logic [NUM_CORES-1:0] halted,trap_illegal,interrupt_taken,retire,
    output logic [31:0] retire_pc[NUM_CORES],retire_instr[NUM_CORES],
    output logic [63:0] cycle_count[NUM_CORES],retired_count[NUM_CORES],
    output logic [63:0] imem_stall_count[NUM_CORES],dmem_stall_count[NUM_CORES]
);
  localparam int unsigned M=2*NUM_CORES;
  mem_if imem[NUM_CORES](clk,rst_n),dmem[NUM_CORES](clk,rst_n),fabric[M](clk,rst_n);
  tagged_mem_if tc[NUM_CORES](clk,rst_n), tm[NUM_CORES](clk,rst_n);
  mem_if ext[1](clk,rst_n);
  generate for(genvar c=0;c<NUM_CORES;c++) begin:g
    cpu_core #(.RESET_PC(RESET_PC)) core(
      .clk(clk),.rst_n(rst_n),.irq(irq[c]),.imem(imem[c]),.dmem(dmem[c]),
      .halted(halted[c]),.trap_illegal(trap_illegal[c]),.interrupt_taken(interrupt_taken[c]),
      .retire(retire[c]),.retire_pc(retire_pc[c]),.retire_instr(retire_instr[c]),
      .cycle_count(cycle_count[c]),.retired_count(retired_count[c]),
      .imem_stall_count(imem_stall_count[c]),.dmem_stall_count(dmem_stall_count[c]));
    l1i_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) ic(.cpu(imem[c]),.memory(fabric[2*c]));
    mem_to_tagged core_bridge(.upstream(dmem[c]),.downstream(tc[c]));
    l1d_nb_cache #(.CACHE_BYTES(L1_BYTES),.LINE_BYTES(LINE_BYTES)) dc(.cpu(tc[c]),.memory(tm[c]));
    tagged_to_mem cache_bridge(.upstream(tm[c]),.downstream(fabric[2*c+1]));
  end endgenerate
  shared_interconnect #(.NUM_MASTERS(M),.NUM_SLAVES(1)) fabric_i(
    .clk(clk),.rst_n(rst_n),.master_port(fabric),.slave_port(ext));
  assign memory.req_valid=ext[0].req_valid; assign memory.req_addr=ext[0].req_addr;
  assign memory.req_write=ext[0].req_write; assign memory.req_wdata=ext[0].req_wdata;
  assign memory.req_be=ext[0].req_be; assign ext[0].req_ready=memory.req_ready;
  assign ext[0].rsp_valid=memory.rsp_valid; assign ext[0].rsp_rdata=memory.rsp_rdata;
  assign ext[0].rsp_error=memory.rsp_error; assign memory.rsp_ready=ext[0].rsp_ready;
endmodule : multicore_cpu_nb
