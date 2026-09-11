// Fixed-function AXI4 rectangle fill engine.
// One accepted command writes width*height constant-color pixels into a
// linear 32-bit framebuffer, using bounded incrementing write bursts.
module axi4_fill_engine #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4,
    parameter int unsigned MAX_BURST_BEATS = 16
) (
    input logic clk, input logic rst_n,
    input logic start,
    input logic [ADDR_W-1:0] base_addr,
    input logic [31:0] stride_bytes,
    input logic [15:0] x, input logic [15:0] y,
    input logic [15:0] width, input logic [15:0] height,
    input logic [DATA_W-1:0] color,
    output logic busy, output logic done, output logic error,
    axi4_if.master axi
);
  localparam int unsigned BEAT_BYTES = DATA_W / 8;
  localparam int unsigned SIZE = $clog2(BEAT_BYTES);
  typedef enum logic [1:0] {S_IDLE, S_AW, S_W, S_B} state_e;
  state_e state_q;
  logic [15:0] row_q, col_q;
  logic [7:0] beat_q;
  logic done_q, error_q;
  logic [ADDR_W-1:0] burst_addr;
  logic [16:0] remaining_pixels;
  logic [8:0] burst_beats;

  assign busy = state_q != S_IDLE;
  assign done = done_q;
  assign error = error_q;
  assign remaining_pixels = {1'b0, width} - {1'b0, col_q};
  assign burst_beats = (remaining_pixels > 17'(MAX_BURST_BEATS)) ?
                       MAX_BURST_BEATS[8:0] : remaining_pixels[8:0];
  assign burst_addr = base_addr + ADDR_W'((ADDR_W'(y) + ADDR_W'(row_q)) * stride_bytes) +
                      ADDR_W'((ADDR_W'(x) + ADDR_W'(col_q)) * BEAT_BYTES);

  assign axi.awid = '0;
  assign axi.awaddr = burst_addr;
  assign axi.awlen = 8'(burst_beats - 1'b1);
  assign axi.awsize = SIZE[2:0];
  assign axi.awburst = 2'b01;
  assign axi.awvalid = state_q == S_AW;
  assign axi.wdata = color;
  assign axi.wstrb = {DATA_W/8{1'b1}};
  assign axi.wlast = (9'(beat_q) == burst_beats - 1'b1);
  assign axi.wvalid = state_q == S_W;
  assign axi.bready = state_q == S_B;

  // This engine only writes. Read channels are tied off so it can share the
  // same full AXI4 interface definition as the GPU read master.
  assign axi.arid = '0; assign axi.araddr = '0; assign axi.arlen = '0;
  assign axi.arsize = '0; assign axi.arburst = '0; assign axi.arvalid = 1'b0;
  assign axi.rready = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= S_IDLE; row_q <= '0; col_q <= '0; beat_q <= '0;
      done_q <= 1'b0; error_q <= 1'b0;
    end else begin
      done_q <= 1'b0;
      unique case (state_q)
        S_IDLE: begin
          if (start && width != 0 && height != 0) begin
            row_q <= 0; col_q <= 0; beat_q <= 0;
            error_q <= 1'b0;
            state_q <= S_AW;
          end
        end
        S_AW: if (axi.awvalid && axi.awready) begin
          beat_q <= 0;
          state_q <= S_W;
        end
        S_W: if (axi.wvalid && axi.wready) begin
          if (axi.wlast) state_q <= S_B;
          else beat_q <= beat_q + 1'b1;
        end
        S_B: if (axi.bvalid && axi.bready) begin
          if (axi.bresp != 2'b00) begin
            error_q <= 1'b1;
            done_q <= 1'b1;
            state_q <= S_IDLE;
          end else if (col_q + 16'(burst_beats) >= width) begin
            if (row_q + 1'b1 >= height) begin
              done_q <= 1'b1;
              state_q <= S_IDLE;
            end else begin
              row_q <= row_q + 1'b1;
              col_q <= 0;
              state_q <= S_AW;
            end
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
endmodule : axi4_fill_engine
