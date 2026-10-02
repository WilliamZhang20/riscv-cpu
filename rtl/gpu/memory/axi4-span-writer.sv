// AXI4 burst writer for one horizontal span of 32-bit framebuffer pixels.
module axi4_span_writer #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4,
    parameter int unsigned MAX_BURST_BEATS = 16
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             span_valid,
    output logic             span_ready,
    input  logic [15:0]      span_x,
    input  logic [15:0]      span_y,
    input  logic [15:0]      span_len,
    input  logic [DATA_W-1:0] span_color,
    input  logic [ADDR_W-1:0] framebuffer_base,
    input  logic [31:0]      stride_bytes,
    output logic             busy,
    axi4_if.master           axi
);
  localparam int unsigned BEAT_BYTES = DATA_W / 8;
  localparam int unsigned SIZE = $clog2(BEAT_BYTES);
  typedef enum logic [1:0] {S_IDLE, S_AW, S_W, S_B} state_e;
  state_e state_q;
  logic [15:0] x_q, y_q, len_q;
  logic [15:0] col_q;
  logic [DATA_W-1:0] color_q;
  logic [ADDR_W-1:0] base_q;
  logic [31:0] stride_q;
  logic [7:0] beat_q;
  logic [ADDR_W-1:0] burst_addr;
  logic [16:0] remaining_pixels;
  logic [8:0] burst_beats;

  assign span_ready = state_q == S_IDLE;
  assign busy = state_q != S_IDLE;
  assign remaining_pixels = {1'b0, len_q} - {1'b0, col_q};
  assign burst_beats = (remaining_pixels > 17'(MAX_BURST_BEATS)) ?
                       MAX_BURST_BEATS[8:0] : remaining_pixels[8:0];
  assign burst_addr = base_q + ADDR_W'((ADDR_W'(y_q) * stride_q)) +
                      ADDR_W'((ADDR_W'(x_q) + ADDR_W'(col_q)) * BEAT_BYTES);

  assign axi.awid = '0;
  assign axi.awaddr = burst_addr;
  assign axi.awlen = 8'(burst_beats - 1'b1);
  assign axi.awsize = SIZE[2:0];
  assign axi.awburst = 2'b01;
  assign axi.awvalid = state_q == S_AW;
  assign axi.wdata = color_q;
  assign axi.wstrb = {DATA_W/8{1'b1}};
  assign axi.wlast = (9'(beat_q) == burst_beats - 1'b1);
  assign axi.wvalid = state_q == S_W;
  assign axi.bready = state_q == S_B;

  assign axi.arid = '0;
  assign axi.araddr = '0;
  assign axi.arlen = '0;
  assign axi.arsize = '0;
  assign axi.arburst = '0;
  assign axi.arvalid = 1'b0;
  assign axi.rready = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= S_IDLE;
      x_q <= '0;
      y_q <= '0;
      len_q <= '0;
      col_q <= '0;
      color_q <= '0;
      base_q <= '0;
      stride_q <= '0;
      beat_q <= '0;
    end else begin
      unique case (state_q)
        S_IDLE: begin
          if (span_valid && span_ready && span_len != 16'd0) begin
            x_q <= span_x;
            y_q <= span_y;
            len_q <= span_len;
            col_q <= '0;
            color_q <= span_color;
            base_q <= framebuffer_base;
            stride_q <= stride_bytes;
            beat_q <= '0;
            state_q <= S_AW;
          end
        end
        S_AW: if (axi.awvalid && axi.awready) begin
          beat_q <= '0;
          state_q <= S_W;
        end
        S_W: if (axi.wvalid && axi.wready) begin
          if (axi.wlast) state_q <= S_B;
          else beat_q <= beat_q + 1'b1;
        end
        S_B: if (axi.bvalid && axi.bready) begin
          if (axi.bresp != 2'b00) begin
            state_q <= S_IDLE;
          end else if (col_q + 16'(burst_beats) >= len_q) begin
            state_q <= S_IDLE;
          end else begin
            col_q <= col_q + 16'(burst_beats);
            state_q <= S_AW;
          end
        end
        default: state_q <= S_IDLE;
      endcase
    end
  end

`ifndef SYNTHESIS
  a_aw_stable_under_backpressure: assert property (@(posedge clk) disable iff (!rst_n)
    axi.awvalid && !axi.awready |=> axi.awvalid && $stable(axi.awaddr) &&
      $stable(axi.awlen) && $stable(axi.awsize) && $stable(axi.awburst));
  a_w_stable_under_backpressure: assert property (@(posedge clk) disable iff (!rst_n)
    axi.wvalid && !axi.wready |=> axi.wvalid && $stable(axi.wdata) &&
      $stable(axi.wstrb) && $stable(axi.wlast));
  a_bounded_burst: assert property (@(posedge clk) disable iff (!rst_n)
    axi.awvalid |-> axi.awlen < 8'(MAX_BURST_BEATS));
`endif
endmodule : axi4_span_writer
