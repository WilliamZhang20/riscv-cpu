// CPU-programmable 2D primitive GPU: solid rectangles and triangles.
// AXI4-Lite command plane; AXI4 span writes to the framebuffer in DRAM.
module primitive_gpu_2d #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4,
    parameter int unsigned MAX_BURST_BEATS = 16
) (
    axi4_lite_if.slave ctrl,
    axi4_if.master data_axi,
    output logic busy,
    output logic done,
    output logic error
);
  logic aw_hold_q, w_hold_q, bvalid_q, rvalid_q;
  logic [ADDR_W-1:0] awaddr_q, base_q;
  logic [DATA_W-1:0] wdata_q, rdata_q, color_q;
  logic [DATA_W/8-1:0] wstrb_q;
  logic [31:0] stride_q;
  logic [15:0] v0_x_q, v0_y_q, v1_x_q, v1_y_q, v2_x_q, v2_y_q;
  logic prim_triangle_q;
  logic start_q, done_q, error_q;
  logic rect_arm_q, tri_arm_q;
  logic rect_done, rect_error, tri_done, tri_error;
  logic writer_error;
  logic span_valid, span_ready;
  logic [15:0] span_x, span_y, span_len;
  logic rect_span_valid, tri_span_valid;
  logic [15:0] rect_span_x, rect_span_y, rect_span_len;
  logic [15:0] tri_span_x, tri_span_y, tri_span_len;
  logic rect_busy, tri_busy, writer_busy;
  logic raster_active_q;
  logic prim_triangle_active_q;
  logic raster_finished_q;
  logic [15:0] rect_w, rect_h;

  assign rect_w = v1_x_q - v0_x_q;
  assign rect_h = v1_y_q - v0_y_q;

  assign span_valid = prim_triangle_active_q ? tri_span_valid : rect_span_valid;
  assign span_x = prim_triangle_active_q ? tri_span_x : rect_span_x;
  assign span_y = prim_triangle_active_q ? tri_span_y : rect_span_y;
  assign span_len = prim_triangle_active_q ? tri_span_len : rect_span_len;

  wire rect_start = rect_arm_q && !rect_busy;
  wire tri_start = tri_arm_q && !tri_busy;

  assign busy = rect_busy || tri_busy || writer_busy || span_valid;
  assign done = done_q;
  assign error = error_q;

  assign ctrl.awready = !aw_hold_q && !bvalid_q;
  assign ctrl.wready = !w_hold_q && !bvalid_q;
  assign ctrl.bvalid = bvalid_q;
  assign ctrl.bresp = 2'b00;
  assign ctrl.arready = !rvalid_q;
  assign ctrl.rvalid = rvalid_q;
  assign ctrl.rdata = rdata_q;
  assign ctrl.rresp = 2'b00;

  axi4_span_writer #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .ID_W(ID_W),
                    .MAX_BURST_BEATS(MAX_BURST_BEATS)) span_writer (
      .clk(ctrl.clk), .rst_n(ctrl.rst_n),
      .span_valid(span_valid), .span_ready(span_ready),
      .span_x(span_x), .span_y(span_y), .span_len(span_len),
      .span_color(color_q), .framebuffer_base(base_q), .stride_bytes(stride_q),
      .busy(writer_busy), .axi(data_axi));

  rect_rasterizer u_rect_rast (
      .clk(ctrl.clk), .rst_n(ctrl.rst_n), .start(rect_start),
      .x(v0_x_q), .y(v0_y_q), .width(rect_w), .height(rect_h),
      .busy(rect_busy), .done(rect_done), .error(rect_error),
      .span_valid(rect_span_valid), .span_ready(span_ready),
      .span_x(rect_span_x), .span_y(rect_span_y), .span_len(rect_span_len));

  triangle_rasterizer u_tri_rast (
      .clk(ctrl.clk), .rst_n(ctrl.rst_n), .start(tri_start),
      .x0(v0_x_q), .y0(v0_y_q), .x1(v1_x_q), .y1(v1_y_q),
      .x2(v2_x_q), .y2(v2_y_q),
      .busy(tri_busy), .done(tri_done), .error(tri_error),
      .span_valid(tri_span_valid), .span_ready(span_ready),
      .span_x(tri_span_x), .span_y(tri_span_y), .span_len(tri_span_len));

  always_ff @(posedge ctrl.clk or negedge ctrl.rst_n) begin
    if (!ctrl.rst_n) begin
      aw_hold_q <= 0;
      w_hold_q <= 0;
      bvalid_q <= 0;
      rvalid_q <= 0;
      awaddr_q <= '0;
      wdata_q <= '0;
      wstrb_q <= '0;
      rdata_q <= '0;
      base_q <= '0;
      stride_q <= '0;
      v0_x_q <= '0;
      v0_y_q <= '0;
      v1_x_q <= '0;
      v1_y_q <= '0;
      v2_x_q <= '0;
      v2_y_q <= '0;
      prim_triangle_q <= 1'b0;
      start_q <= 0;
      rect_arm_q <= 0;
      tri_arm_q <= 0;
      done_q <= 0;
      error_q <= 0;
      raster_active_q <= 1'b0;
      prim_triangle_active_q <= 1'b0;
      raster_finished_q <= 1'b0;
      writer_error <= 1'b0;
    end else begin
      start_q <= 1'b0;

      if (rect_done) rect_arm_q <= 1'b0;
      if (tri_done) tri_arm_q <= 1'b0;

      if (data_axi.bvalid && data_axi.bready && data_axi.bresp != 2'b00)
        writer_error <= 1'b1;

      if (ctrl.awvalid && ctrl.awready) begin
        aw_hold_q <= 1'b1;
        awaddr_q <= ctrl.awaddr;
      end
      if (ctrl.wvalid && ctrl.wready) begin
        w_hold_q <= 1'b1;
        wdata_q <= ctrl.wdata;
        wstrb_q <= ctrl.wstrb;
      end
      if (bvalid_q && ctrl.bready) bvalid_q <= 1'b0;
      if (aw_hold_q && w_hold_q && !bvalid_q) begin
        aw_hold_q <= 1'b0;
        w_hold_q <= 1'b0;
        bvalid_q <= 1'b1;
        unique case (awaddr_q[5:2])
          4'd0: begin
            if (wdata_q[0]) begin
              start_q <= 1'b1;
              done_q <= 1'b0;
              error_q <= 1'b0;
              writer_error <= 1'b0;
              raster_active_q <= 1'b1;
              raster_finished_q <= 1'b0;
              prim_triangle_active_q <= prim_triangle_q;
              if (prim_triangle_q) tri_arm_q <= 1'b1;
              else if (v1_x_q >= v0_x_q && v1_y_q >= v0_y_q) rect_arm_q <= 1'b1;
              else begin
                done_q <= 1'b1;
                error_q <= 1'b1;
                raster_active_q <= 1'b0;
              end
            end
            if (wdata_q[1] && !wdata_q[0]) begin
              done_q <= 1'b0;
              error_q <= 1'b0;
              writer_error <= 1'b0;
              raster_active_q <= 1'b0;
              rect_arm_q <= 1'b0;
              tri_arm_q <= 1'b0;
            end
          end
          4'd1: for (int b = 0; b < DATA_W/8; b++)
            if (wstrb_q[b]) base_q[8*b +: 8] <= wdata_q[8*b +: 8];
          4'd2: for (int b = 0; b < DATA_W/8; b++)
            if (wstrb_q[b]) stride_q[8*b +: 8] <= wdata_q[8*b +: 8];
          4'd3: prim_triangle_q <= wdata_q[0];
          4'd4: begin
            v0_x_q <= wdata_q[15:0];
            v0_y_q <= wdata_q[31:16];
          end
          4'd5: begin
            v1_x_q <= wdata_q[15:0];
            v1_y_q <= wdata_q[31:16];
          end
          4'd6: begin
            v2_x_q <= wdata_q[15:0];
            v2_y_q <= wdata_q[31:16];
          end
          4'd7: color_q <= wdata_q;
          default: ;
        endcase
      end

      if (rect_done || tri_done) raster_finished_q <= 1'b1;

      if (raster_finished_q && !writer_busy && !span_valid) begin
        done_q <= 1'b1;
        error_q <= writer_error | rect_error | tri_error;
        raster_active_q <= 1'b0;
        raster_finished_q <= 1'b0;
      end

      if (rvalid_q && ctrl.rready) rvalid_q <= 1'b0;
      if (ctrl.arvalid && ctrl.arready) begin
        rvalid_q <= 1'b1;
        unique case (ctrl.araddr[5:2])
          4'd0: rdata_q <= 32'b0;
          4'd1: rdata_q <= base_q;
          4'd2: rdata_q <= stride_q;
          4'd3: rdata_q <= {31'b0, prim_triangle_q};
          4'd4: rdata_q <= {v0_y_q, v0_x_q};
          4'd5: rdata_q <= {v1_y_q, v1_x_q};
          4'd6: rdata_q <= {v2_y_q, v2_x_q};
          4'd7: rdata_q <= color_q;
          4'd8: rdata_q <= (busy ? 32'd1 : 32'd0) |
                              (done_q ? 32'd2 : 32'd0) |
                              (error_q ? 32'd4 : 32'd0);
          default: rdata_q <= '0;
        endcase
      end
    end
  end
endmodule : primitive_gpu_2d
