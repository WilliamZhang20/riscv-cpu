// Canonical GPU top (moved from rtl/gpu/primitive-gpu-2d.sv).
// TODO: rename module primitive_gpu_2d -> gpu once tb/soc instantiations
// are updated; rect walk moves to rtl/gpu/raster/rect-rasterizer.sv next.
// CPU-programmable solid rectangle renderer.
// AXI4-Lite is the command/configuration plane; AXI4 writes the framebuffer.
module primitive_gpu_2d #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4,
    parameter int unsigned MAX_BURST_BEATS = 16
) (
    axi4_lite_if.slave ctrl,
    axi4_if.master data_axi,
    output logic busy, output logic done, output logic error
);
  logic aw_hold_q, w_hold_q, bvalid_q, rvalid_q;
  logic [ADDR_W-1:0] awaddr_q, base_q;
  logic [DATA_W-1:0] wdata_q, rdata_q, color_q;
  logic [DATA_W/8-1:0] wstrb_q;
  logic [31:0] stride_q;
  logic [15:0] x_q, y_q, width_q, height_q;
  logic start_q, done_q, error_q;
  logic fill_done, fill_error;

  // Register map:
  // 00 command (bit 0=start, bit 1=clear status)
  // 04 framebuffer base, 08 stride bytes, 0c x/y, 10 width/height,
  // 14 solid RGBA/RGBX color, 18 status (busy|done|error).
  assign ctrl.awready = !aw_hold_q && !bvalid_q;
  assign ctrl.wready = !w_hold_q && !bvalid_q;
  assign ctrl.bvalid = bvalid_q;
  assign ctrl.bresp = 2'b00;
  assign ctrl.arready = !rvalid_q;
  assign ctrl.rvalid = rvalid_q;
  assign ctrl.rdata = rdata_q;
  assign ctrl.rresp = 2'b00;

  axi4_fill_engine #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .ID_W(ID_W),
                     .MAX_BURST_BEATS(MAX_BURST_BEATS)) fill (
      .clk(ctrl.clk), .rst_n(ctrl.rst_n), .start(start_q),
      .base_addr(base_q), .stride_bytes(stride_q), .x(x_q), .y(y_q),
      .width(width_q), .height(height_q), .color(color_q), .busy(busy),
      .done(fill_done), .error(fill_error), .axi(data_axi));
  assign done = done_q;
  assign error = error_q;

  always_ff @(posedge ctrl.clk or negedge ctrl.rst_n) begin
    if (!ctrl.rst_n) begin
      aw_hold_q <= 0; w_hold_q <= 0; bvalid_q <= 0; rvalid_q <= 0;
      awaddr_q <= '0; wdata_q <= '0; wstrb_q <= '0; rdata_q <= '0;
      base_q <= '0; stride_q <= '0; x_q <= '0; y_q <= '0;
      width_q <= '0; height_q <= '0; color_q <= '0;
      start_q <= 0; done_q <= 0; error_q <= 0;
    end else begin
      start_q <= 1'b0;
      if (ctrl.awvalid && ctrl.awready) begin
        aw_hold_q <= 1'b1; awaddr_q <= ctrl.awaddr;
      end
      if (ctrl.wvalid && ctrl.wready) begin
        w_hold_q <= 1'b1; wdata_q <= ctrl.wdata; wstrb_q <= ctrl.wstrb;
      end
      if (bvalid_q && ctrl.bready) bvalid_q <= 1'b0;
      if (aw_hold_q && w_hold_q && !bvalid_q) begin
        aw_hold_q <= 1'b0; w_hold_q <= 1'b0; bvalid_q <= 1'b1;
        unique case (awaddr_q[5:2])
          4'd0: begin
            if (wdata_q[0]) begin start_q <= 1'b1; done_q <= 1'b0; error_q <= 1'b0; end
            if (wdata_q[1]) begin done_q <= 1'b0; error_q <= 1'b0; end
          end
          4'd1: for (int b = 0; b < DATA_W/8; b++)
            if (wstrb_q[b]) base_q[8*b +: 8] <= wdata_q[8*b +: 8];
          4'd2: for (int b = 0; b < DATA_W/8; b++)
            if (wstrb_q[b]) stride_q[8*b +: 8] <= wdata_q[8*b +: 8];
          4'd3: begin x_q <= wdata_q[15:0]; y_q <= wdata_q[31:16]; end
          4'd4: begin width_q <= wdata_q[15:0]; height_q <= wdata_q[31:16]; end
          4'd5: color_q <= wdata_q;
          default: ;
        endcase
      end
      if (fill_done) begin done_q <= 1'b1; error_q <= fill_error; end
      if (rvalid_q && ctrl.rready) rvalid_q <= 1'b0;
      if (ctrl.arvalid && ctrl.arready) begin
        rvalid_q <= 1'b1;
        unique case (ctrl.araddr[5:2])
          4'd0: rdata_q <= 32'b0;
          4'd1: rdata_q <= base_q;
          4'd2: rdata_q <= stride_q;
          4'd3: rdata_q <= {y_q, x_q};
          4'd4: rdata_q <= {height_q, width_q};
          4'd5: rdata_q <= color_q;
          4'd6: rdata_q <= (busy ? 32'd1 : 32'd0) |
                              (done_q ? 32'd2 : 32'd0) |
                              (error_q ? 32'd4 : 32'd0);
          default: rdata_q <= '0;
        endcase
      end
    end
  end
endmodule : primitive_gpu_2d
