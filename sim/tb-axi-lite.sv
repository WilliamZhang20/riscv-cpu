module axi_lite_mem #(parameter int unsigned WORDS=256)(axi4_lite_if.slave axi);
  logic [31:0] mem [WORDS]; logic aw_hold,w_hold,bvalid_q,rvalid_q; logic [31:0] aw_q,wdata_q,rdata_q; logic [3:0] strb_q; logic [2:0] delay_q;
  assign axi.awready = !aw_hold && !bvalid_q; assign axi.wready = !w_hold && !bvalid_q;
  assign axi.bvalid = bvalid_q; assign axi.bresp = 2'b00;
  assign axi.arready = !rvalid_q && !bvalid_q; assign axi.rvalid = rvalid_q; assign axi.rdata=rdata_q; assign axi.rresp=2'b00;
  always_ff @(posedge axi.clk or negedge axi.rst_n) begin
    if (!axi.rst_n) begin aw_hold<=0; w_hold<=0; bvalid_q<=0; rvalid_q<=0; delay_q<=0; rdata_q<=0; end
    else begin
      if (axi.awvalid && axi.awready) begin aw_hold<=1; aw_q<=axi.awaddr; end
      if (axi.wvalid && axi.wready) begin w_hold<=1; wdata_q<=axi.wdata; strb_q<=axi.wstrb; end
      if (aw_hold && w_hold && !bvalid_q) begin
        for (int b=0;b<4;b++) if (strb_q[b]) mem[aw_q[9:2]][8*b +: 8] <= wdata_q[8*b +: 8];
        bvalid_q<=1;
      end
      if (bvalid_q && axi.bready) begin bvalid_q<=0; aw_hold<=0; w_hold<=0; end
      if (axi.arvalid && axi.arready) begin rdata_q<=mem[axi.araddr[9:2]]; delay_q<=3; end
      if (delay_q != 0) delay_q<=delay_q-1'b1;
      if (delay_q == 1) rvalid_q<=1;
      if (rvalid_q && axi.rready) rvalid_q<=0;
    end
  end
endmodule

module tb_axi_lite;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  mem_if mem(clk,rst_n); axi4_lite_if axi(clk,rst_n);
  mem_to_axi_lite dut(.upstream(mem),.axi(axi));
  axi_lite_mem slave(.axi(axi));
  task automatic access(input logic wr, input logic [31:0] addr, input logic [31:0] data,
                        input logic [3:0] be, output logic [31:0] rd, output logic err);
    begin
      @(negedge clk); mem.req_addr=addr; mem.req_write=wr; mem.req_wdata=data; mem.req_be=be; mem.req_valid=1; mem.rsp_ready=0;
      while (!mem.req_ready) @(posedge clk); @(negedge clk); mem.req_valid=0; mem.rsp_ready=1;
      while (!mem.rsp_valid) @(posedge clk); rd=mem.rsp_rdata; err=mem.rsp_error; @(negedge clk); mem.rsp_ready=0;
    end
  endtask
  logic [31:0] rd; logic err;
  initial begin
    mem.req_valid=0; mem.rsp_ready=0; repeat(3) @(posedge clk); rst_n=1;
    access(1,32'h40,32'h11223344,4'hf,rd,err); if(err) $fatal(1,"write error");
    access(0,32'h40,0,4'hf,rd,err); if(err || rd!==32'h11223344) $fatal(1,"read %08h err=%0b",rd,err);
    access(1,32'h40,32'h0000aa00,4'b0010,rd,err); access(0,32'h40,0,4'hf,rd,err);
    if(err || rd!==32'h1122aa44) $fatal(1,"byte write %08h",rd);
    $display("tb_axi_lite: PASS"); $finish;
  end
endmodule
