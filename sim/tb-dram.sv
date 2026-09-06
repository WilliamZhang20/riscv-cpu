module tb_dram;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  mem_if bus(clk,rst_n);
  dram_model #(.MEM_BYTES(1024), .READ_LATENCY(5), .WRITE_LATENCY(3)) dut(.bus(bus));
  task automatic access(input bit wr, input [31:0] addr, input [31:0] data, output [31:0] result, output int latency);
    longint unsigned start;
    $display("access start t=%0t wr=%0b ready=%0b", $time, wr, bus.req_ready);
    @(negedge clk); bus.req_valid=1; bus.req_write=wr; bus.req_addr=addr; bus.req_wdata=data; bus.req_be=4'hf; bus.rsp_ready=0;
    while (!bus.req_ready) @(negedge clk); @(posedge clk); #1; bus.req_valid=0; start=$time;
    while (!bus.rsp_valid) begin #1; end latency=int'($time-start); result=bus.rsp_rdata; bus.rsp_ready=1; @(posedge clk);
  endtask
  initial begin
    logic [31:0] r; int lat;
    bus.req_valid=0; bus.req_write=0; bus.req_addr=0; bus.req_wdata=0; bus.req_be=0; bus.rsp_ready=1;
    repeat(2) @(posedge clk); rst_n<=1; @(negedge clk);
    access(1,32'h20,32'hdead_beef,r,lat); if(lat < 30) $fatal("DRAM write latency too short");
    access(0,32'h20,0,r,lat); if(r !== 32'hdead_beef || lat < 50) $fatal("DRAM read failed r=%08h lat=%0d",r,lat);
    $display("tb_dram: PASS (read latency %0d ns)",lat); $finish;
  end
endmodule
