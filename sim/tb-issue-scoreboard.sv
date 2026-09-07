module tb_issue_scoreboard;
  logic clk=0, rst_n=0, valid0,valid1,writes0,writes1,commit_valid0,commit_valid1;
  logic [4:0] rs1_0,rs2_0,rd0,rs1_1,rs2_1,rd1,commit_rd0,commit_rd1;
  logic rs1_0_used,rs2_0_used,rs1_1_used,rs2_1_used,issue0,issue1;
  always #5 clk=~clk;
  issue_scoreboard dut(.*);
  task automatic drive(input logic v0,input logic [4:0] d0,input logic w0,
                       input logic v1,input logic [4:0] d1,input logic w1,
                       input logic u1,input logic [4:0] s1);
    valid0=v0; rd0=d0; writes0=w0; rs1_0_used=0; rs2_0_used=0;
    valid1=v1; rd1=d1; writes1=w1; rs1_1_used=u1; rs1_1=s1; rs2_1_used=0;
    #1;
  endtask
  initial begin
    valid0=0;valid1=0;writes0=0;writes1=0;commit_valid0=0;commit_valid1=0;
    rs1_0=0;rs2_0=0;rd0=0;rs1_1=0;rs2_1=0;rd1=0;commit_rd0=0;commit_rd1=0;
    rs1_0_used=0;rs2_0_used=0;rs1_1_used=0;rs2_1_used=0;
    rst_n=1; #1; rst_n=0; repeat(2) @(posedge clk); rst_n=1; #1;
    drive(1,1,1,1,2,1,0,0);
    if (!issue0 || !issue1) $fatal(1,"independent pair did not issue");
    @(posedge clk); #1;
    drive(1,3,1,1,4,1,1,1);
    if (!issue0 || issue1) $fatal(1,"dependency bypassed scoreboard");
    @(posedge clk); #1;
    commit_valid0=1; commit_rd0=1; @(posedge clk); #1; commit_valid0=0;
    drive(1,5,1,1,4,1,1,1);
    if (!issue0 || !issue1) $fatal(1,"pair did not issue after commit");
    @(posedge clk); #1;
    drive(0,0,0,1,6,1,0,0);
    if (issue0 || issue1) $fatal(1,"lane 1 issued without lane 0");
    @(posedge clk); #1;
    drive(1,7,1,1,7,1,0,0);
    if (!issue0 || issue1) $fatal(1,"same-cycle WAW was not blocked");
    @(posedge clk); #1;
    commit_valid0=1; commit_rd0=5; commit_valid1=1; commit_rd1=7; @(posedge clk); #1; commit_valid0=0; commit_valid1=0;
    drive(1,5,1,0,0,0,0,0);
    if (!issue0) $fatal(1,"busy destination was not released by commit");
    @(posedge clk); #1;
    @(posedge clk); #1;
    $display("tb_issue_scoreboard: PASS"); $finish;
  end
endmodule
