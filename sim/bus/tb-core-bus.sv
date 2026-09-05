// ============================================================================
// Bus-facing CPU integration test.
// ============================================================================
module tb_core_bus;

  localparam int MEM_WORDS = 1024;
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0500;
  localparam logic [31:0] MAGIC_PASS  = 32'h600D_C0DE;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  mem_if core_if [2](clk, rst_n);
  mem_if memory_if [1](clk, rst_n);

  logic halted, trap_illegal, retire;
  logic [31:0] retire_pc, retire_instr;

  cpu_core u_core (
      .clk          (clk),
      .rst_n        (rst_n),
      .imem        (core_if[0]),
      .dmem        (core_if[1]),
      .halted      (halted),
      .trap_illegal (trap_illegal),
      .retire       (retire),
      .retire_pc    (retire_pc),
      .retire_instr (retire_instr)
  );

  shared_interconnect #(
      .NUM_MASTERS (2),
      .NUM_SLAVES  (1)
  ) u_interconnect (
      .clk         (clk),
      .rst_n       (rst_n),
      .master_port (core_if),
      .slave_port  (memory_if)
  );

  sync_memory #(
      .MEM_BYTES (4096)
  ) u_memory (
      .bus (memory_if[0])
  );

  string prog;
  int unsigned cycles;

  always @(posedge clk)
    if (rst_n) begin
      cycles++;
    end

  initial begin
    if (!$value$plusargs("PROG=%s", prog)) prog = "test-basic.hex";

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
    // sync_memory clears storage during reset, so load the image after reset.
    @(negedge clk);
    $readmemh(prog, u_memory.mem);

    while (!halted && cycles < 100000) @(posedge clk);

    if (!halted)
      $fatal(1, "bus core timeout at pc=%08h", retire_pc);
    if (trap_illegal)
      $fatal(1, "bus core illegal instruction %08h at pc=%08h",
             retire_instr, retire_pc);
    if (u_memory.mem[RESULT_ADDR[11:2]] !== MAGIC_PASS)
      $fatal(1, "bus core result mismatch: got %08h",
             u_memory.mem[RESULT_ADDR[11:2]]);

    $display("tb_core_bus: PASS after %0d cycles", cycles);
    $finish;
  end

endmodule : tb_core_bus
