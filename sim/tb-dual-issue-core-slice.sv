module tb_dual_issue_core_slice;
  logic clk=0,rst_n=0,fetch_start,fetch_busy,pair_valid,pair_ready;
  logic [31:0] fetch_pc,pair_pc,instr0,instr1;
  logic issue0,issue1,commit_valid0,commit_valid1;
  logic [4:0] commit_rd0,commit_rd1;
  logic [31:0] commit_data0,commit_data1;
  mem_if imem0(clk,rst_n),imem1(clk,rst_n);
  logic p0,p1; logic [31:0] d0,d1;
  always #5 clk=~clk;
  dual_issue_core_slice dut(.*);
  assign pair_ready=issue0 && issue1;
  assign imem0.req_ready=1; assign imem1.req_ready=1;
  assign imem0.rsp_valid=p0; assign imem1.rsp_valid=p1;
  assign imem0.rsp_rdata=d0; assign imem1.rsp_rdata=d1;
  assign imem0.rsp_error=0; assign imem1.rsp_error=0;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin p0<=0;p1<=0;d0<=0;d1<=0; end
    else begin
      p0<=imem0.req_valid; p1<=imem1.req_valid;
      if(imem0.req_valid) d0<=32'h00A0_0093;
      if(imem1.req_valid) d1<=32'h0010_8133;
      if(imem0.rsp_valid && imem0.rsp_ready) p0<=0;
      if(imem1.rsp_valid && imem1.rsp_ready) p1<=0;
    end
  end
  initial begin
    fetch_start=0;fetch_pc=32'h400;
    repeat(2) @(negedge clk); rst_n=1;
    @(posedge clk); fetch_start=1; @(posedge clk); fetch_start=0;
    wait(commit_valid0); #1;
    if(commit_rd0!=1 || commit_data0!=32'd10)
      $fatal(1,"lane 0 did not commit before dependent lane 1");
    wait(commit_valid1); #1;
    if(commit_rd1!=2 || commit_data1!=32'd20)
      $fatal(1,"commit metadata was not preserved");
    $display("tb_dual_issue_core_slice: PASS"); $finish;
  end
endmodule
