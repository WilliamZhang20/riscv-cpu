// Scanline triangle rasterizer using three edge functions (integer, no FP).
module triangle_rasterizer #(
    parameter int unsigned COORD_W = 16,
    parameter int unsigned EDGE_W = 40
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [COORD_W-1:0] x0,
    input  logic [COORD_W-1:0] y0,
    input  logic [COORD_W-1:0] x1,
    input  logic [COORD_W-1:0] y1,
    input  logic [COORD_W-1:0] x2,
    input  logic [COORD_W-1:0] y2,
    output logic             busy,
    output logic             done,
    output logic             error,
    output logic             span_valid,
    input  logic             span_ready,
    output logic [15:0]      span_x,
    output logic [15:0]      span_y,
    output logic [15:0]      span_len
);
  logic [COORD_W-1:0] xmin, xmax, ymin, ymax;
  logic signed [EDGE_W-1:0] e0_a, e0_b, e0_c, e1_a, e1_b, e1_c, e2_a, e2_b, e2_c;

  triangle_setup #(.COORD_W(COORD_W), .EDGE_W(EDGE_W)) setup (
      .x0(x0), .y0(y0), .x1(x1), .y1(y1), .x2(x2), .y2(y2),
      .xmin(xmin), .xmax(xmax), .ymin(ymin), .ymax(ymax),
      .e0_a(e0_a), .e0_b(e0_b), .e0_c(e0_c),
      .e1_a(e1_a), .e1_b(e1_b), .e1_c(e1_c),
      .e2_a(e2_a), .e2_b(e2_b), .e2_c(e2_c));

  typedef enum logic [2:0] {T_IDLE, T_ROW, T_SCAN, T_EMIT, T_WAIT} state_e;
  state_e state_q;
  logic [COORD_W-1:0] y_cur, x_cur;
  logic [COORD_W-1:0] span_x_q, span_len_q;
  logic [15:0] run_start;
  logic inside_run;
  logic done_q, error_q;

  function automatic logic signed [EDGE_W-1:0] eval_edge(
      input logic signed [EDGE_W-1:0] a,
      input logic signed [EDGE_W-1:0] b,
      input logic signed [EDGE_W-1:0] c,
      input logic [COORD_W-1:0] x,
      input logic [COORD_W-1:0] y
  );
    logic signed [EDGE_W-1:0] sx, sy;
    sx = EDGE_W'( $signed({{EDGE_W-COORD_W{1'b0}}, x}) );
    sy = EDGE_W'( $signed({{EDGE_W-COORD_W{1'b0}}, y}) );
    return a * sx + b * sy + c;
  endfunction

  function automatic logic pixel_inside(input logic [COORD_W-1:0] x, input logic [COORD_W-1:0] y);
    return eval_edge(e0_a, e0_b, e0_c, x, y) >= 0 &&
           eval_edge(e1_a, e1_b, e1_c, x, y) >= 0 &&
           eval_edge(e2_a, e2_b, e2_c, x, y) >= 0;
  endfunction

  assign busy = state_q != T_IDLE;
  assign done = done_q;
  assign error = error_q;
  assign span_x = span_x_q;
  assign span_y = y_cur;
  assign span_len = span_len_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= T_IDLE;
      y_cur <= '0;
      x_cur <= '0;
      span_x_q <= '0;
      span_len_q <= '0;
      run_start <= '0;
      inside_run <= 1'b0;
      done_q <= 1'b0;
      error_q <= 1'b0;
      span_valid <= 1'b0;
    end else begin
      unique case (state_q)
        T_IDLE: begin
          span_valid <= 1'b0;
          if (start) begin
            done_q <= 1'b0;
            error_q <= 1'b0;
            if (ymin > ymax) begin
              done_q <= 1'b1;
            end else begin
              y_cur <= ymin;
              state_q <= T_ROW;
            end
          end
        end
        T_ROW: begin
          x_cur <= xmin;
          inside_run <= 1'b0;
          state_q <= T_SCAN;
        end
        T_SCAN: begin
          if (x_cur > xmax) begin
            if (inside_run) begin
              span_x_q <= run_start;
              span_len_q <= x_cur - run_start;
              span_valid <= 1'b1;
              state_q <= T_EMIT;
            end else if (y_cur >= ymax) begin
              done_q <= 1'b1;
              state_q <= T_IDLE;
            end else begin
              y_cur <= y_cur + 16'd1;
              state_q <= T_ROW;
            end
          end else if (pixel_inside(x_cur, y_cur)) begin
            if (!inside_run) begin
              run_start <= x_cur;
              inside_run <= 1'b1;
            end
            x_cur <= x_cur + 16'd1;
          end else begin
            if (inside_run) begin
              span_x_q <= run_start;
              span_len_q <= x_cur - run_start;
              span_valid <= 1'b1;
              state_q <= T_EMIT;
            end else begin
              x_cur <= x_cur + 16'd1;
            end
          end
        end
        T_EMIT: begin
          if (span_valid && span_ready) begin
            span_valid <= 1'b0;
            inside_run <= 1'b0;
            if (x_cur > xmax) begin
              if (y_cur >= ymax) begin
                done_q <= 1'b1;
                state_q <= T_IDLE;
              end else begin
                y_cur <= y_cur + 16'd1;
                state_q <= T_WAIT;
              end
            end else begin
              state_q <= T_SCAN;
            end
          end
        end
        T_WAIT: begin
          state_q <= T_ROW;
        end
        default: state_q <= T_IDLE;
      endcase
    end
  end
endmodule : triangle_rasterizer
