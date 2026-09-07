module tb_axi4_gpu_engine;
  logic clk = 0, rst_n = 0;
  axi4_lite_if ctrl(clk, rst_n);
  axi4_if data_axi(clk, rst_n);
  logic stream_valid, stream_ready = 1'b1;
  logic [31:0] stream_data;
  logic busy, done, error;
  logic data_active;
  logic [31:0] burst_base;
  logic [7:0] burst_len, burst_beat;
  int seen;

  always #5 clk = ~clk;
  axi4_gpu_engine dut(
      .ctrl(ctrl), .data_axi(data_axi), .stream_valid(stream_valid),
      .stream_ready(stream_ready), .stream_data(stream_data),
      .busy(busy), .done(done), .error(error));

  assign data_axi.arready = !data_active;
  assign data_axi.rvalid = data_active;
  assign data_axi.rid = '0;
  assign data_axi.rdata = burst_base + 32'(burst_beat * 4);
  assign data_axi.rresp = 2'b00;
  assign data_axi.rlast = burst_beat == burst_len;
  assign data_axi.awready = 1'b0; assign data_axi.wready = 1'b0;
  assign data_axi.bvalid = 1'b0; assign data_axi.bid = '0;
  assign data_axi.bresp = 2'b00;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_active <= 1'b0; burst_base <= '0; burst_len <= '0;
      burst_beat <= '0;
    end else if (data_axi.arvalid && data_axi.arready) begin
      data_active <= 1'b1; burst_base <= data_axi.araddr;
      burst_len <= data_axi.arlen; burst_beat <= '0;
    end else if (data_axi.rvalid && data_axi.rready) begin
      if (data_axi.rlast) data_active <= 1'b0;
      else burst_beat <= burst_beat + 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && stream_valid && stream_ready) begin
      if (stream_data !== (32'h8000_0000 + 32'(seen * 4)))
        $fatal(1, "bad GPU stream beat %0d: %h", seen, stream_data);
      seen++;
    end
  end

  task automatic lite_write(input logic [31:0] addr, input logic [31:0] value);
    begin
      // AXI-Lite write channels are presented together for this directed test.
      ctrl.awaddr = addr; ctrl.awvalid = 1'b1;
      ctrl.wdata = value; ctrl.wstrb = 4'b1111; ctrl.wvalid = 1'b1;
      @(posedge clk);
      ctrl.awvalid = 1'b0; ctrl.wvalid = 1'b0;
      do @(posedge clk); while (!ctrl.bvalid);
      // Response is accepted below.
      ctrl.bready = 1'b1; @(posedge clk); ctrl.bready = 1'b0;
    end
  endtask

  initial begin
    ctrl.awaddr = '0; ctrl.awvalid = 0; ctrl.wdata = '0; ctrl.wstrb = '0;
    ctrl.wvalid = 0; ctrl.bready = 0; ctrl.araddr = '0;
    ctrl.arvalid = 0; ctrl.rready = 0; seen = 0;
    repeat (2) @(posedge clk); rst_n = 1'b1;
    lite_write(32'h4, 32'h8000_0000);
    lite_write(32'h8, 32'd20);
    lite_write(32'h0, 32'd1);
    wait(done); #1;
    if (error || busy || seen != 20)
      $fatal(1, "GPU engine failed: error=%0d busy=%0d seen=%0d", error, busy, seen);
    $display("tb_axi4_gpu_engine: PASS (%0d beats)", seen);
    $finish;
  end
endmodule
