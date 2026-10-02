// Solid-axis-aligned rectangle -> horizontal span stream.
module rect_rasterizer #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [15:0]      x,
    input  logic [15:0]      y,
    input  logic [15:0]      width,
    input  logic [15:0]      height,
    output logic             busy,
    output logic             done,
    output logic             error,
    output logic             span_valid,
    input  logic             span_ready,
    output logic [15:0]      span_x,
    output logic [15:0]      span_y,
    output logic [15:0]      span_len
);
  typedef enum logic [1:0] {R_IDLE, R_EMIT, R_WAIT} state_e;
  state_e state_q;
  logic [15:0] x_q, y_q, width_q, height_q;
  logic [15:0] row_q;
  logic done_q, error_q;

  assign busy = state_q != R_IDLE;
  assign done = done_q;
  assign error = error_q;
  assign span_x = x_q;
  assign span_y = y_q + row_q;
  assign span_len = width_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= R_IDLE;
      x_q <= '0;
      y_q <= '0;
      width_q <= '0;
      height_q <= '0;
      row_q <= '0;
      done_q <= 1'b0;
      error_q <= 1'b0;
      span_valid <= 1'b0;
    end else begin
      unique case (state_q)
        R_IDLE: begin
          span_valid <= 1'b0;
          if (start) begin
            done_q <= 1'b0;
            x_q <= x;
            y_q <= y;
            width_q <= width;
            height_q <= height;
            row_q <= '0;
            error_q <= 1'b0;
            if (width == 16'd0 || height == 16'd0) begin
              done_q <= 1'b1;
            end else begin
              state_q <= R_EMIT;
            end
          end
        end
        R_EMIT: begin
          span_valid <= 1'b1;
          if (span_valid && span_ready) begin
            if (row_q + 16'd1 >= height_q) begin
              span_valid <= 1'b0;
              done_q <= 1'b1;
              state_q <= R_IDLE;
            end else begin
              row_q <= row_q + 16'd1;
              state_q <= R_WAIT;
            end
          end
        end
        R_WAIT: begin
          span_valid <= 1'b0;
          state_q <= R_EMIT;
        end
        default: state_q <= R_IDLE;
      endcase
    end
  end
endmodule : rect_rasterizer
