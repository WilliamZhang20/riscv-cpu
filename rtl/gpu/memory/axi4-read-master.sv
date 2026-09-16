// Simple burst reader for a future raster/compute engine.
// It converts a start/base/beat-count command into AXI4 INCR bursts and a
// backpressured stream. At most one burst is outstanding.
module axi4_read_master #(
    parameter int unsigned ADDR_W=32,
    parameter int unsigned DATA_W=32,
    parameter int unsigned ID_W=4,
    parameter int unsigned MAX_BURST_BEATS=16
) (
    input logic clk, input logic rst_n,
    input logic start,
    input logic [ADDR_W-1:0] base_addr,
    input logic [31:0] beat_count,
    output logic busy, output logic done, output logic error,
    output logic data_valid, input logic data_ready,
    output logic [DATA_W-1:0] data,
    axi4_if.master axi
);
  localparam int unsigned BEAT_BYTES=DATA_W/8;
  localparam int unsigned SIZE=$clog2(BEAT_BYTES);
  typedef enum logic [2:0] {IDLE, AR, READ, STREAM} state_t;
  state_t state_q;
  logic [ADDR_W-1:0] addr_q;
  logic [31:0] remain_q;
  logic [7:0] burst_len_q;
  logic [7:0] beat_q;
  logic error_q, done_q;
  assign busy = state_q != IDLE;
  assign done = done_q;
  assign error = error_q;
  assign data_valid = state_q == STREAM && axi.rvalid;
  assign data = axi.rdata;
  assign axi.arid = '0;
  assign axi.araddr = addr_q;
  assign axi.arlen = burst_len_q - 1'b1;
  assign axi.arsize = SIZE[2:0];
  assign axi.arburst = 2'b01;
  assign axi.arvalid = state_q == AR;
  assign axi.rready = (state_q == STREAM) && data_ready;
  assign axi.awid='0; assign axi.awaddr='0; assign axi.awlen='0;
  assign axi.awsize='0; assign axi.awburst='0; assign axi.awvalid=1'b0;
  assign axi.wdata='0; assign axi.wstrb='0; assign axi.wlast=1'b0;
  assign axi.wvalid=1'b0; assign axi.bready=1'b1;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q<=IDLE; addr_q<='0; remain_q<='0; burst_len_q<='0;
      beat_q<='0; error_q<=1'b0; done_q<=1'b0;
    end else begin
      done_q <= 1'b0;
      if (state_q == IDLE) begin
        if (start && beat_count != 0) begin
          addr_q <= base_addr;
          remain_q <= beat_count;
          burst_len_q <= (beat_count > MAX_BURST_BEATS) ? MAX_BURST_BEATS[7:0] : beat_count[7:0];
          error_q <= 1'b0;
          state_q <= AR;
        end
      end else if (state_q == AR) begin
        if (axi.arvalid && axi.arready) begin
          beat_q <= 0;
          state_q <= STREAM;
        end
      end else if (state_q == STREAM) begin
        if (axi.rvalid && axi.rready) begin
          if (axi.rresp != 2'b00) error_q <= 1'b1;
          if (axi.rlast) begin
            if (remain_q <= burst_len_q) begin
              remain_q <= 0;
              done_q <= 1'b1;
              state_q <= IDLE;
            end else begin
              remain_q <= remain_q - 32'(burst_len_q);
              addr_q <= addr_q + ADDR_W'(burst_len_q * BEAT_BYTES);
              burst_len_q <= ((remain_q - 32'(burst_len_q)) > MAX_BURST_BEATS) ?
                             MAX_BURST_BEATS[7:0] : 8'(remain_q - 32'(burst_len_q));
              state_q <= AR;
            end
          end else begin
            beat_q <= beat_q + 1'b1;
          end
        end
      end
    end
  end
`ifndef SYNTHESIS
  a_ar_stable_under_backpressure: assert property (@(posedge clk) disable iff (!rst_n) axi.arvalid && !axi.arready |=> $stable(axi.araddr) && $stable(axi.arlen) && $stable(axi.arsize) && $stable(axi.arburst));
  a_no_write_channels: assert property (@(posedge clk) disable iff (!rst_n) !axi.awvalid && !axi.wvalid);
`endif
endmodule : axi4_read_master
