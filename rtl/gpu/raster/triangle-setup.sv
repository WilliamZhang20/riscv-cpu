// Integer triangle setup: bounding box + three edge functions E(x,y)=A*x+B*y+C.
module triangle_setup #(
    parameter int unsigned COORD_W = 16,
    parameter int unsigned EDGE_W = 40
) (
    input  logic [COORD_W-1:0] x0,
    input  logic [COORD_W-1:0] y0,
    input  logic [COORD_W-1:0] x1,
    input  logic [COORD_W-1:0] y1,
    input  logic [COORD_W-1:0] x2,
    input  logic [COORD_W-1:0] y2,
    output logic [COORD_W-1:0] xmin,
    output logic [COORD_W-1:0] xmax,
    output logic [COORD_W-1:0] ymin,
    output logic [COORD_W-1:0] ymax,
    output logic signed [EDGE_W-1:0] e0_a,
    output logic signed [EDGE_W-1:0] e0_b,
    output logic signed [EDGE_W-1:0] e0_c,
    output logic signed [EDGE_W-1:0] e1_a,
    output logic signed [EDGE_W-1:0] e1_b,
    output logic signed [EDGE_W-1:0] e1_c,
    output logic signed [EDGE_W-1:0] e2_a,
    output logic signed [EDGE_W-1:0] e2_b,
    output logic signed [EDGE_W-1:0] e2_c
);
  function automatic logic signed [EDGE_W-1:0] sext(input logic [COORD_W-1:0] v);
    return EDGE_W'( $signed({{EDGE_W-COORD_W{1'b0}}, v}) );
  endfunction

  function automatic void edge_coeff(
      input logic [COORD_W-1:0] xa,
      input logic [COORD_W-1:0] ya,
      input logic [COORD_W-1:0] xb,
      input logic [COORD_W-1:0] yb,
      output logic signed [EDGE_W-1:0] a,
      output logic signed [EDGE_W-1:0] b,
      output logic signed [EDGE_W-1:0] c
  );
    logic signed [EDGE_W-1:0] sa, sb, sc, sd;
    sa = sext(ya);
    sb = sext(yb);
    sc = sext(xa);
    sd = sext(xb);
    a = sa - sb;
    b = sd - sc;
    c = sc * sb - sd * sa;
  endfunction

  logic signed [EDGE_W-1:0] a0, b0, c0, a1, b1, c1, a2, b2, c2;
  logic signed [EDGE_W-1:0] area;
  logic flip;

  always_comb begin
    xmin = x0;
    xmax = x0;
    ymin = y0;
    ymax = y0;
    if (x1 < xmin) xmin = x1;
    if (x2 < xmin) xmin = x2;
    if (x1 > xmax) xmax = x1;
    if (x2 > xmax) xmax = x2;
    if (y1 < ymin) ymin = y1;
    if (y2 < ymin) ymin = y2;
    if (y1 > ymax) ymax = y1;
    if (y2 > ymax) ymax = y2;

    edge_coeff(x0, y0, x1, y1, a0, b0, c0);
    edge_coeff(x1, y1, x2, y2, a1, b1, c1);
    edge_coeff(x2, y2, x0, y0, a2, b2, c2);

    area = (sext(x1) - sext(x0)) * (sext(y2) - sext(y0)) -
           (sext(x2) - sext(x0)) * (sext(y1) - sext(y0));
    flip = area < 0;

    if (flip) begin
      e0_a = -a0;
      e0_b = -b0;
      e0_c = -c0;
      e1_a = -a1;
      e1_b = -b1;
      e1_c = -c1;
      e2_a = -a2;
      e2_b = -b2;
      e2_c = -c2;
    end else begin
      e0_a = a0;
      e0_b = b0;
      e0_c = c0;
      e1_a = a1;
      e1_b = b1;
      e1_c = c1;
      e2_a = a2;
      e2_b = b2;
      e2_c = c2;
    end
  end
endmodule : triangle_setup
