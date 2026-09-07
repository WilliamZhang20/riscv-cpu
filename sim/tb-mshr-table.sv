module tb_mshr_table;
  logic clk=0, rst_n=0, alloc_valid, alloc_ready, alloc_fire;
  logic [3:0] alloc_id, rsp_id, free_id;
  logic [31:0] alloc_line, rsp_line;
  logic rsp_valid, rsp_hit, free_valid;
  always #5 clk=~clk;
  mshr_table #(.ENTRIES(2),.ID_W(4)) dut(.*);

  task automatic allocate(input logic [3:0] id, input logic [31:0] line);
    alloc_id=id; alloc_line=line; alloc_valid=1;
    while (!alloc_ready) @(negedge clk);
    @(posedge clk); #1 alloc_valid=0;
  endtask

  initial begin
    alloc_valid=0; rsp_valid=0; free_valid=0; alloc_id=0; alloc_line=0;
    rsp_id=0; free_id=0;
    repeat(2) @(negedge clk); rst_n=1;
    allocate(4'h3,32'h1000); allocate(4'ha,32'h2000);
    if (alloc_ready) $fatal(1,"MSHR accepted more than its capacity");
    rsp_id=4'ha; rsp_valid=1; #1;
    if (!rsp_hit || rsp_line != 32'h2000) $fatal(1,"out-of-order response lookup failed");
    @(posedge clk); rsp_valid=0;
    free_id=4'ha; free_valid=1; @(posedge clk); #1; free_valid=0;
    if (!alloc_ready) $fatal(1,"MSHR slot was not freed");
    rsp_id=4'h3; rsp_valid=1; #1;
    if (!rsp_hit || rsp_line != 32'h1000) $fatal(1,"remaining response lookup failed");
    $display("tb_mshr_table: PASS"); $finish;
  end
endmodule
