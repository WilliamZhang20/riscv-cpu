module tb_dual_fetch_pair;
  logic clk=0,rst_n=0,start=0,pair_valid,pair_ready,busy,pair_error;
  logic [31:0] start_pc,pair_pc,instr0,instr1;
  mem_if imem0(clk,rst_n), imem1(clk,rst_n);
  logic p0,p1; logic [31:0] a0,a1;
  always #5 clk=~clk;
  dual_fetch_pair dut(.*);
  assign imem0.req_ready=1; assign imem1.req_ready=1;
  assign imem0.rsp_valid=p0; assign imem1.rsp_valid=p1;
  assign imem0.rsp_rdata=a0; assign imem1.rsp_rdata=a1;
  assign imem0.rsp_error=0; assign imem1.rsp_error=0;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin p0<=0;p1<=0;a0<=0;a1<=0; end
    else begin
      p0<=imem0.req_valid; p1<=imem1.req_valid;
      if(imem0.req_valid) a0<=imem0.req_addr ^ 32'h1000;
      if(imem1.req_valid) a1<=imem1.req_addr ^ 32'h1000;
      if(imem0.rsp_valid && imem0.rsp_ready) p0<=0;
      if(imem1.rsp_valid && imem1.rsp_ready) p1<=0;
    end
  end
  initial begin
    start_pc=32'h400; pair_ready=0;
    repeat(2) @(negedge clk); rst_n=1;
    @(posedge clk); start=1; @(posedge clk); start=0;
    wait(pair_valid); #1;
    if(pair_pc!=32'h400 || instr0!=32'h1400 || instr1!=32'h1404 || pair_error)
      $fatal(1,"fetch pair mismatch pc=%h i0=%h i1=%h",pair_pc,instr0,instr1);
    repeat(2) @(posedge clk); #1;
    if(!pair_valid || pair_pc!=32'h400) $fatal(1,"pair was not held under backpressure");
    pair_ready=1; @(posedge clk); #1;
    if(busy) $fatal(1,"fetch pair remained busy after consume");
    $display("tb_dual_fetch_pair: PASS"); $finish;
  end
endmodule
