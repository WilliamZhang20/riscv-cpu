module tb_multicore_dual_issue;
  logic clk = 0, rst_n = 0;
  logic [0:0] irq = '0;
  logic [0:0] halted, trap_illegal, interrupt_taken, retire_valid0, retire_valid1;
  logic [31:0] retire_pc0 [1], retire_pc1 [1];
  logic [31:0] retire_instr0 [1], retire_instr1 [1];
  logic [4:0] retire_rd0 [1], retire_rd1 [1];
  logic [31:0] retire_data0 [1], retire_data1 [1];
  logic [63:0] cycle_count [1], retired_count [1];
  mem_if memory_if(clk, rst_n);

  always #5 clk = ~clk;

  multicore_cpu_dual_issue #(.NUM_CORES(1)) dut (
      .clk(clk), .rst_n(rst_n), .irq(irq), .memory(memory_if),
      .halted(halted), .trap_illegal(trap_illegal),
      .interrupt_taken(interrupt_taken), .retire_valid0(retire_valid0),
      .retire_valid1(retire_valid1), .retire_pc0(retire_pc0),
      .retire_pc1(retire_pc1), .retire_instr0(retire_instr0),
      .retire_instr1(retire_instr1), .retire_rd0(retire_rd0),
      .retire_rd1(retire_rd1), .retire_data0(retire_data0),
      .retire_data1(retire_data1), .cycle_count(cycle_count),
      .retired_count(retired_count));
  sync_memory #(.MEM_BYTES(4096)) memory(.bus(memory_if));

  initial begin
    repeat (3) @(negedge clk);
    for (int i = 0; i < 4096/4; i++) memory.mem[i] = 32'h0000_0013;
    memory.mem[0] = 32'h0050_0093; // addi x1,x0,5
    memory.mem[1] = 32'h0070_0113; // addi x2,x0,7
    memory.mem[2] = 32'h0020_81b3; // add x3,x1,x2
    memory.mem[3] = 32'h1030_2023; // sw x3,0x100(x0)
    memory.mem[4] = 32'h1000_2203; // lw x4,0x100(x0)
    memory.mem[5] = 32'h0032_0463; // beq x4,x3,+8
    memory.mem[6] = 32'h0010_0293; // skipped
    memory.mem[7] = 32'h0090_0293; // target
    memory.mem[8] = 32'h0000_0073; // ecall
    rst_n = 1'b1;
    wait (halted[0]);
    repeat (2) @(posedge clk);
    if (trap_illegal[0]) $fatal(1, "dual-issue multicore illegal trap");
    if (memory.mem[32'h100 >> 2] !== 32'd12)
      $fatal(1, "dual-issue multicore store failed: %h", memory.mem[32'h100 >> 2]);
    if (retired_count[0] < 7) $fatal(1, "too few retirements: %0d", retired_count[0]);
    $display("tb_multicore_dual_issue: PASS (%0d retirements)", retired_count[0]);
    $finish;
  end
endmodule
