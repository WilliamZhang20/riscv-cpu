module tb_primitive_gpu_2d;
  logic clk = 0, rst_n = 0;
  axi4_lite_if ctrl(clk, rst_n);
  axi4_if data_axi(clk, rst_n);
  logic busy, done, error;
  logic aw_pending, bvalid;
  logic [31:0] awaddr;
  logic [7:0] wbeat;
  logic [31:0] framebuffer [256];

  always #5 clk = ~clk;

  primitive_gpu_2d #(.MAX_BURST_BEATS(4)) dut (
      .ctrl(ctrl), .data_axi(data_axi), .busy(busy), .done(done), .error(error));

  assign data_axi.awready = !aw_pending && !bvalid;
  assign data_axi.wready = aw_pending && !bvalid;
  assign data_axi.bvalid = bvalid;
  assign data_axi.bid = '0;
  assign data_axi.bresp = 2'b00;
  assign data_axi.arready = 1'b0;
  assign data_axi.rvalid = 1'b0;
  assign data_axi.rid = '0;
  assign data_axi.rdata = '0;
  assign data_axi.rresp = 2'b00;
  assign data_axi.rlast = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_pending <= 1'b0;
      bvalid <= 1'b0;
      awaddr <= '0;
      wbeat <= '0;
      for (int i = 0; i < 256; i++) framebuffer[i] <= 32'hDEAD_BEEF;
    end else begin
      if (bvalid && data_axi.bready) bvalid <= 1'b0;
      if (data_axi.awvalid && data_axi.awready) begin
        aw_pending <= 1'b1;
        awaddr <= data_axi.awaddr;
        wbeat <= '0;
      end
      if (data_axi.wvalid && data_axi.wready) begin
        framebuffer[(awaddr >> 2) + 32'(wbeat)] <= data_axi.wdata;
        if (data_axi.wlast) begin
          aw_pending <= 1'b0;
          bvalid <= 1'b1;
        end else begin
          wbeat <= wbeat + 1'b1;
        end
      end
    end
  end

  task lite_write(input [31:0] addr, input [31:0] value);
    ctrl.awaddr = addr;
    ctrl.awvalid = 1'b1;
    ctrl.wdata = value;
    ctrl.wstrb = 4'hf;
    ctrl.wvalid = 1'b1;
    @(posedge clk);
    ctrl.awvalid = 1'b0;
    ctrl.wvalid = 1'b0;
    do @(posedge clk); while (!ctrl.bvalid);
    ctrl.bready = 1'b1;
    @(posedge clk);
    ctrl.bready = 1'b0;
  endtask

  task wait_done;
    integer i;
    for (i = 0; i < 5000; i = i + 1) begin
      @(posedge clk);
      if (done) i = 5000;
    end
    if (!done) $fatal(1, "GPU timeout (busy=%b done=%b)", busy, done);
  endtask

  initial begin
    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    lite_write(32'h04, 32'h0000_0100);
    lite_write(32'h08, 32'd16);
    lite_write(32'h0c, 32'd0);
    lite_write(32'h10, {16'd1, 16'd1});
    lite_write(32'h14, {16'd3, 16'd4});
    lite_write(32'h1c, 32'hAABB_CCDD);
    lite_write(32'h00, 32'd1);
    wait_done;

    for (int i = 0; i < 3; i++) begin
      if (framebuffer[69 + i] !== 32'hAABB_CCDD)
        $fatal(1, "row 1 pixel %0d incorrect: %h", i, framebuffer[69 + i]);
      if (framebuffer[73 + i] !== 32'hAABB_CCDD)
        $fatal(1, "row 2 pixel %0d incorrect: %h", i, framebuffer[73 + i]);
    end
    if (framebuffer[68] !== 32'hDEAD_BEEF || framebuffer[72] !== 32'hDEAD_BEEF)
      $fatal(1, "fill overwrote outside rectangle fb68=%h fb72=%h", framebuffer[68], framebuffer[72]);
    $display("tb_primitive_gpu_2d: PASS (3x2 rectangle)");

    lite_write(32'h04, 32'h0000_0200);
    lite_write(32'h0c, 32'd1);
    lite_write(32'h10, {16'd0, 16'd0});
    lite_write(32'h14, {16'd0, 16'd4});
    lite_write(32'h18, {16'd3, 16'd2});
    lite_write(32'h1c, 32'h1122_3344);
    lite_write(32'h00, 32'd2);
    lite_write(32'h00, 32'd1);
    wait_done;

    if (error) $fatal(1, "triangle GPU error");
    $display("tb_primitive_gpu_2d: PASS (triangle done, fb130=%h)", framebuffer[130]);
    $finish;
  end
endmodule
