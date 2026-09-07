module tb_dual_issue_alu;
  import rv32i_pkg::*;
  logic clk=0, rst_n=0;
  logic valid0,valid1,writes0,writes1,rs1_0_used,rs2_0_used,rs1_1_used,rs2_1_used;
  logic [4:0] rs1_0,rs2_0,rd0,rs1_1,rs2_1,rd1;
  logic [31:0] a0,b0,a1,b1;
  alu_op_e op0,op1;
  logic issue0,issue1,commit_valid0,commit_valid1;
  logic [4:0] commit_rd0,commit_rd1;
  logic [31:0] commit_data0,commit_data1;
  always #5 clk=~clk;
  dual_issue_alu dut(.*);

  task automatic drive(input logic v0,input logic [4:0] d0,input logic w0,
                       input logic v1,input logic [4:0] d1,input logic w1,
                       input logic dep1);
    valid0=v0; rd0=d0; writes0=w0; rs1_0_used=0; rs2_0_used=0;
    valid1=v1; rd1=d1; writes1=w1; rs1_1_used=dep1; rs1_1=d0; rs2_1_used=0;
    a0=32'd10; b0=32'd7; op0=ALU_ADD; a1=32'd20; b1=32'd3; op1=ALU_SUB;
    #1;
  endtask

  initial begin
    valid0=0;valid1=0;writes0=0;writes1=0;rs1_0_used=0;rs2_0_used=0;
    rs1_1_used=0;rs2_1_used=0;rs1_0=0;rs2_0=0;rd0=0;rs1_1=0;rs2_1=0;rd1=0;
    a0=0;b0=0;a1=0;b1=0;op0=ALU_ADD;op1=ALU_ADD;
    repeat(2) @(negedge clk); rst_n=1;
    drive(1,1,1,1,2,1,0);
    if (!issue0 || !issue1) $fatal(1,"independent pair did not issue");
    @(posedge clk); #1;
    if (!commit_valid0 || commit_rd0 != 1 || commit_data0 != 17 ||
        !commit_valid1 || commit_rd1 != 2 || commit_data1 != 17)
      $fatal(1,"dual ALU commit mismatch");
    drive(1,3,1,1,4,1,1);
    if (!issue0 || issue1) $fatal(1,"dependent lane bypassed scoreboard");
    @(posedge clk); #1;
    $display("tb_dual_issue_alu: PASS"); $finish;
  end
endmodule
