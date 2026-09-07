module tb_gpu_axi_read;
  logic clk=0, rst_n=0, start=0, data_ready=0;
  logic [31:0] base_addr;
  logic [31:0] beat_count;
  logic busy, done, error, data_valid;
  logic [31:0] data;
  axi4_if axi(clk,rst_n);
  logic active;
  logic [31:0] slave_base;
  logic [7:0] slave_len, slave_beat;
  int seen;

  always #5 clk=~clk;
  axi4_read_master dut(.*);

  assign axi.arready = !active;
  assign axi.rvalid = active;
  assign axi.rid = '0;
  assign axi.rdata = slave_base + 32'(slave_beat * 4);
  assign axi.rresp = 2'b00;
  assign axi.rlast = slave_beat == slave_len;
  assign axi.awready=1'b0; assign axi.wready=1'b0; assign axi.bvalid=1'b0;
  assign axi.bid='0; assign axi.bresp=2'b00;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active<=0; slave_base<='0; slave_len<='0; slave_beat<='0;
    end else begin
      if (axi.arvalid && axi.arready) begin
        active<=1; slave_base<=axi.araddr; slave_len<=axi.arlen; slave_beat<=0;
      end else if (axi.rvalid && axi.rready) begin
        if (axi.rlast) active<=0;
        else slave_beat<=slave_beat+1'b1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst_n && data_valid && data_ready) begin
      if (data !== (base_addr + 32'(seen*4))) $fatal(1,"bad AXI data at beat %0d",seen);
      seen++;
    end
  end

  initial begin
    base_addr=32'h8000_0000; beat_count=20; seen=0;
    repeat(2) @(posedge clk); rst_n=1;
    @(posedge clk); start=1; @(posedge clk); start=0;
    repeat(2) @(posedge clk); data_ready=0;
    repeat(3) @(posedge clk); data_ready=1;
    wait(done); #1;
    if (error || seen != 20) $fatal(1,"AXI read failed: error=%0d seen=%0d",error,seen);
    if (busy) $fatal(1,"reader remained busy after done");
    $display("tb_gpu_axi_read: PASS (%0d beats)",seen); $finish;
  end
endmodule
