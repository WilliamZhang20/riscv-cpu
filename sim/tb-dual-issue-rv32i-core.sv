module tb_dual_issue_rv32i_core;
  logic clk = 0, rst_n = 0, irq = 0;
  logic halted, trap_illegal, interrupt_taken;
  logic retire_valid0, retire_valid1;
  logic [31:0] retire_pc0, retire_pc1, retire_instr0, retire_instr1;
  logic [4:0] retire_rd0, retire_rd1;
  logic [31:0] retire_data0, retire_data1;
  logic [63:0] cycle_count, retired_count;
  mem_if imem0(clk, rst_n), imem1(clk, rst_n), dmem(clk, rst_n);
  int retire_total;

  always #5 clk = ~clk;

  dual_issue_rv32i_core dut (
      .clk(clk), .rst_n(rst_n), .irq(irq),
      .imem0(imem0), .imem1(imem1), .dmem(dmem),
      .halted(halted), .trap_illegal(trap_illegal),
      .interrupt_taken(interrupt_taken),
      .retire_valid0(retire_valid0), .retire_pc0(retire_pc0),
      .retire_instr0(retire_instr0), .retire_rd0(retire_rd0),
      .retire_data0(retire_data0), .retire_valid1(retire_valid1),
      .retire_pc1(retire_pc1), .retire_instr1(retire_instr1),
      .retire_rd1(retire_rd1), .retire_data1(retire_data1),
      .cycle_count(cycle_count), .retired_count(retired_count));

  sync_memory #(.MEM_BYTES(256)) imem0_model(.bus(imem0));
  sync_memory #(.MEM_BYTES(256)) imem1_model(.bus(imem1));
  sync_memory #(.MEM_BYTES(256)) data_model(.bus(dmem));

  always @(posedge clk) begin
    if (rst_n) begin
      if (retire_valid0) retire_total++;
      if (retire_valid1) retire_total++;
    end
  end

  initial begin
    // Pair 0: independent instructions should retire together.
    // Pair 1: lane 1 consumes lane 0's result, so it must wait.
    // Pair 2: load followed by dependent branch, then branch to pair 3.
    // Pair 3: lane 1 is ECALL, which halts after lane 0 retires.
    repeat (2) @(negedge clk);
    for (int i = 0; i < 256/4; i++) begin
      imem0_model.mem[i] = 32'h0000_0013;
      imem1_model.mem[i] = 32'h0000_0013;
    end
    imem0_model.mem[0] = 32'h0050_0093; // addi x1,x0,5
    imem0_model.mem[1] = 32'h0070_0113; // addi x2,x0,7
    imem0_model.mem[2] = 32'h0020_81b3; // add x3,x1,x2
    imem0_model.mem[3] = 32'h0030_2023; // sw x3,0(x0)
    imem0_model.mem[4] = 32'h0000_2203; // lw x4,0(x0)
    imem0_model.mem[5] = 32'h0032_0463; // beq x4,x3,+8
    imem0_model.mem[6] = 32'h0010_0293; // skipped addi x5,x0,1
    imem0_model.mem[7] = 32'h0090_0293; // target addi x5,x0,9
    imem0_model.mem[8] = 32'h0000_0073; // ecall
    for (int i = 0; i < 9; i++)
      imem1_model.mem[i] = imem0_model.mem[i];
    rst_n = 1'b1;
    wait (halted);
    repeat (2) @(posedge clk);
    #1;
    if (trap_illegal) $fatal(1, "unexpected illegal instruction trap");
    if (data_model.mem[0] !== 32'd12)
      $fatal(1, "store did not receive x3=12: %h", data_model.mem[0]);
    if (retire_total < 7)
      $fatal(1, "too few retirements: %0d", retire_total);
    $display("tb_dual_issue_rv32i_core: PASS (%0d retirements)", retire_total);
    $finish;
  end
endmodule
