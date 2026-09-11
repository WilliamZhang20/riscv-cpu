// End-to-end CPU workload through the AXI-Lite multicore wrapper.
module tb_multicore_axi_lite;
  localparam logic [31:0] RESULT_ADDR=32'h500, MAGIC_PASS=32'h600d_c0de;
  logic clk=0, rst_n=0;
  logic [0:0] irq='0, halted, trap_illegal, interrupt_taken, retire;
  logic [31:0] retire_pc[1], retire_instr[1]; logic [63:0] cycle_count[1], retired_count[1], imem_stall_count[1], dmem_stall_count[1];
  axi4_lite_if axi(clk,rst_n); always #5 clk=~clk;
  multicore_cpu_axi_lite #(.NUM_CORES(1)) dut(
    .clk(clk),.rst_n(rst_n),.irq(irq),.halted(halted),.trap_illegal(trap_illegal),.interrupt_taken(interrupt_taken),.retire(retire),
    .retire_pc(retire_pc),.retire_instr(retire_instr),.cycle_count(cycle_count),.retired_count(retired_count),
    .imem_stall_count(imem_stall_count),.dmem_stall_count(dmem_stall_count),.axi_memory(axi));
  axi_lite_mem #(.WORDS(1024)) slave(.axi(axi));
  string prog; int unsigned cycles, maxcyc;
  always @(posedge clk) if (rst_n) cycles++;
  initial begin
    if (!$value$plusargs("PROG=%s",prog)) prog="test-basic.hex";
    if (!$value$plusargs("MAXCYC=%d",maxcyc)) maxcyc=200000;
    repeat(3) @(posedge clk); rst_n=1;
    @(negedge clk); $readmemh(prog,slave.mem);
    while (!halted[0] && cycles<maxcyc) @(posedge clk);
    if (cycles>=maxcyc) $fatal(1,"CPU AXI-Lite workload timed out");
    if (trap_illegal[0]) $fatal(1,"CPU AXI-Lite workload trapped illegal instruction");
    if (slave.mem[RESULT_ADDR[9:2]]!==MAGIC_PASS)
      $fatal(1,"CPU AXI-Lite result=%08h",slave.mem[RESULT_ADDR[9:2]]);
    $display("tb_multicore_axi_lite: PASS (%0d cycles, %0d retires)",cycles,retired_count[0]);
    $finish;
  end
endmodule
