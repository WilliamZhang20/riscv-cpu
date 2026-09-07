module tb_dual_issue_decode_execute;
  logic clk=0, rst_n=0, valid0,valid1;
  logic [31:0] pc0,pc1,instr0,instr1;
  logic issue0,issue1,commit_valid0,commit_valid1;
  logic [4:0] commit_rd0,commit_rd1;
  logic [31:0] commit_data0,commit_data1;
  always #5 clk=~clk;
  dual_issue_decode_execute dut(.*);

  initial begin
    valid0=0;valid1=0;pc0=0;pc1=4;instr0=0;instr1=0;
    repeat(2) @(negedge clk); rst_n=1;
    // ADDI x1,x0,10 and ADDI x2,x0,20.
    instr0=32'h00A0_0093; instr1=32'h0140_0113;
    valid0=1; valid1=1; #1;
    if (!issue0 || !issue1) $fatal(1,"independent decoded pair did not issue");
    @(posedge clk); #1;
    if (!commit_valid0 || commit_rd0!=1 || commit_data0!=10 ||
        !commit_valid1 || commit_rd1!=2 || commit_data1!=20)
      $fatal(1,"decoded ADDI results incorrect");
    // ADDI x3,x0,7 followed by ADD x4,x3,x3: lane 1 must wait.
    instr0=32'h0070_0193; instr1=32'h0031_8233;
    #1;
    if (!issue0 || issue1) $fatal(1,"decoded RAW dependency was bypassed");
    $display("tb_dual_issue_decode_execute: PASS"); $finish;
  end
endmodule
