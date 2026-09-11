// CPU/GPU composition root: uncached 0x8000_0000 MMIO controls the rectangle GPU.
module multicore_gpu_soc #(parameter int unsigned NUM_CORES=1) (
  input logic clk,input logic rst_n,input logic [NUM_CORES-1:0] irq,
  mem_if.master memory, axi4_if.master framebuffer_axi,
  output logic [NUM_CORES-1:0] halted,trap_illegal,interrupt_taken,retire,
  output logic [31:0] retire_pc[NUM_CORES],retire_instr[NUM_CORES],
  output logic [63:0] cycle_count[NUM_CORES],retired_count[NUM_CORES],imem_stall_count[NUM_CORES],dmem_stall_count[NUM_CORES],
  output logic gpu_busy,gpu_done,gpu_error
);
  mem_if cpu_memory(clk,rst_n); axi4_lite_if gpu_ctrl(clk,rst_n);
  multicore_cpu #(.NUM_CORES(NUM_CORES)) cpu(
    .clk(clk),.rst_n(rst_n),.memory(cpu_memory),.irq(irq),.halted(halted),.trap_illegal(trap_illegal),.interrupt_taken(interrupt_taken),.retire(retire),.retire_pc(retire_pc),.retire_instr(retire_instr),
    .cycle_count(cycle_count),.retired_count(retired_count),.imem_stall_count(imem_stall_count),.dmem_stall_count(dmem_stall_count));
  mem_gpu_mmio_router mmio(.upstream(cpu_memory),.memory(memory),.gpu_ctrl(gpu_ctrl));
  primitive_gpu_2d gpu(.ctrl(gpu_ctrl),.data_axi(framebuffer_axi),.busy(gpu_busy),.done(gpu_done),.error(gpu_error));
endmodule : multicore_gpu_soc
