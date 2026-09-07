// CPU-programmable GPU memory engine.
// AXI4-Lite is the control/status plane; AXI4 is the high-bandwidth data plane.
// The ordered stream can feed scanout, a texture unit, or a command decoder.
module axi4_gpu_engine #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4,
    parameter int unsigned MAX_BURST_BEATS = 16
) (
    axi4_lite_if.slave ctrl,
    axi4_if.master data_axi,
    output logic stream_valid,
    input logic stream_ready,
    output logic [DATA_W-1:0] stream_data,
    output logic busy, output logic done, output logic error
);
  logic aw_hold_q, w_hold_q, bvalid_q, rvalid_q;
  logic [ADDR_W-1:0] awaddr_q;
  logic [DATA_W-1:0] wdata_q;
  logic [DATA_W/8-1:0] wstrb_q;
  logic [ADDR_W-1:0] base_q;
  logic [31:0] count_q;
  logic done_q, error_q, reader_done, reader_error;
  logic reader_start;
  logic [DATA_W-1:0] rdata_q;
  axi4_if #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .ID_W(ID_W)) reader_axi(
      ctrl.clk, ctrl.rst_n);

  assign ctrl.awready = !aw_hold_q && !bvalid_q;
  assign ctrl.wready  = !w_hold_q && !bvalid_q;
  assign ctrl.bvalid  = bvalid_q;
  assign ctrl.bresp   = 2'b00;
  assign ctrl.arready = !rvalid_q;
  assign ctrl.rvalid  = rvalid_q;
  assign ctrl.rdata   = rdata_q;
  assign ctrl.rresp   = 2'b00;
  assign reader_start = aw_hold_q && w_hold_q &&
                        (awaddr_q[5:2] == 4'd0) && wdata_q[0];

  axi4_read_master #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .ID_W(ID_W),
                     .MAX_BURST_BEATS(MAX_BURST_BEATS)) reader (
      .clk(ctrl.clk), .rst_n(ctrl.rst_n), .start(reader_start),
      .base_addr(base_q), .beat_count(count_q), .busy(busy),
      .done(reader_done), .error(reader_error),
      .data_valid(stream_valid), .data_ready(stream_ready),
      .data(stream_data), .axi(reader_axi));

  assign data_axi.awid = reader_axi.awid;
  assign data_axi.awaddr = reader_axi.awaddr;
  assign data_axi.awlen = reader_axi.awlen;
  assign data_axi.awsize = reader_axi.awsize;
  assign data_axi.awburst = reader_axi.awburst;
  assign data_axi.awvalid = reader_axi.awvalid;
  assign data_axi.wdata = reader_axi.wdata;
  assign data_axi.wstrb = reader_axi.wstrb;
  assign data_axi.wlast = reader_axi.wlast;
  assign data_axi.wvalid = reader_axi.wvalid;
  assign data_axi.bready = reader_axi.bready;
  assign data_axi.arid = reader_axi.arid;
  assign data_axi.araddr = reader_axi.araddr;
  assign data_axi.arlen = reader_axi.arlen;
  assign data_axi.arsize = reader_axi.arsize;
  assign data_axi.arburst = reader_axi.arburst;
  assign data_axi.arvalid = reader_axi.arvalid;
  assign data_axi.rready = reader_axi.rready;
  assign reader_axi.awready = data_axi.awready;
  assign reader_axi.wready = data_axi.wready;
  assign reader_axi.bid = data_axi.bid;
  assign reader_axi.bresp = data_axi.bresp;
  assign reader_axi.bvalid = data_axi.bvalid;
  assign reader_axi.arready = data_axi.arready;
  assign reader_axi.rid = data_axi.rid;
  assign reader_axi.rdata = data_axi.rdata;
  assign reader_axi.rresp = data_axi.rresp;
  assign reader_axi.rlast = data_axi.rlast;
  assign reader_axi.rvalid = data_axi.rvalid;
  assign done = done_q;
  assign error = error_q;

  always_ff @(posedge ctrl.clk or negedge ctrl.rst_n) begin
    if (!ctrl.rst_n) begin
      aw_hold_q <= 0; w_hold_q <= 0; bvalid_q <= 0; rvalid_q <= 0;
      awaddr_q <= '0; wdata_q <= '0; wstrb_q <= '0; base_q <= '0;
      count_q <= '0; done_q <= 0; error_q <= 0; rdata_q <= '0;
    end else begin
      if (ctrl.awvalid && ctrl.awready) begin aw_hold_q <= 1; awaddr_q <= ctrl.awaddr; end
      if (ctrl.wvalid && ctrl.wready) begin w_hold_q <= 1; wdata_q <= ctrl.wdata; wstrb_q <= ctrl.wstrb; end
      if (bvalid_q && ctrl.bready) bvalid_q <= 0;
      if (aw_hold_q && w_hold_q && !bvalid_q) begin
        aw_hold_q <= 0; w_hold_q <= 0; bvalid_q <= 1;
        if (awaddr_q[5:2] == 4'd1) begin
          for (int b = 0; b < DATA_W/8; b++) if (wstrb_q[b]) base_q[8*b +: 8] <= wdata_q[8*b +: 8];
        end else if (awaddr_q[5:2] == 4'd2) begin
          for (int b = 0; b < DATA_W/8; b++) if (wstrb_q[b]) count_q[8*b +: 8] <= wdata_q[8*b +: 8];
        end else if (awaddr_q[5:2] == 4'd0 && wdata_q[1]) begin
          done_q <= 0; error_q <= 0;
        end
      end
      if (reader_done) begin done_q <= 1; error_q <= reader_error; end
      if (rvalid_q && ctrl.rready) rvalid_q <= 0;
      if (ctrl.arvalid && ctrl.arready) begin
        rvalid_q <= 1;
        unique case (ctrl.araddr[5:2])
          4'd0: rdata_q <= busy ? 32'd1 : 32'd0;
          4'd1: rdata_q <= base_q;
          4'd2: rdata_q <= count_q;
          4'd3: rdata_q <= (busy ? 32'd1 : 32'd0) | (done_q ? 32'd2 : 32'd0) | (error_q ? 32'd4 : 32'd0);
          default: rdata_q <= '0;
        endcase
      end
    end
  end
endmodule : axi4_gpu_engine
