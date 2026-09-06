// Full multicore executable smoke test: two cores share the real L1/L2,
// coherence hub, interconnect, and clocked memory path.
module tb_multicore;
  localparam int unsigned MEM_BYTES = 4096;
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0500;
  localparam logic [31:0] MAGIC_PASS  = 32'h600D_C0DE;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  mem_if memory_if(clk, rst_n);
  logic [1:0] halted, trap_illegal, retire;
  logic [1:0] irq = 2'b0, interrupt_taken;
  logic [31:0] retire_pc [2], retire_instr [2];

  multicore_cpu #(.NUM_CORES(2)) dut (
      .clk(clk), .rst_n(rst_n), .memory(memory_if),
      .irq(irq), .halted(halted), .trap_illegal(trap_illegal), .interrupt_taken(interrupt_taken), .retire(retire),
      .retire_pc(retire_pc), .retire_instr(retire_instr));

  sync_memory #(.MEM_BYTES(MEM_BYTES)) memory (.bus(memory_if));

  string prog;
  int unsigned cycles = 0, retired = 0, maxcyc;
  always @(posedge clk) if (rst_n) begin
    cycles++;
    if (retire[0]) retired++; if (retire[1]) retired++;
  end

  initial begin
    if (!$value$plusargs("PROG=%s", prog)) prog = "test-basic.hex";
    if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 200000;
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
    @(negedge clk);
    $readmemh(prog, memory.mem);
    $display("tb_multicore: loaded %s", prog);

    while ((halted != 2'b11) && (cycles < maxcyc)) @(posedge clk);
    if (cycles >= maxcyc) $fatal(1, "FAIL: multicore timeout");
    if (|trap_illegal) $fatal(1, "FAIL: illegal instruction trapped");
    if (memory.mem[RESULT_ADDR[11:2]] !== MAGIC_PASS)
      $fatal(1, "FAIL: shared result=%08h", memory.mem[RESULT_ADDR[11:2]]);
    if (retired < 300) $fatal(1, "FAIL: too few retires=%0d", retired);
    $display("tb_multicore: PASS (%0d cycles, %0d retires)", cycles, retired);
    $finish;
  end
endmodule
