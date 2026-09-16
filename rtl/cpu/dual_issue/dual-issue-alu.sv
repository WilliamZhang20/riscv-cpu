// Two-wide in-order integer execution shell.
// The decoder supplies two adjacent candidates; issue_scoreboard provides the
// conservative dependency/WAW policy. Results commit one cycle after issue.
module dual_issue_alu
  import rv32i_pkg::*;
#(
    parameter int unsigned REG_COUNT=32,
    parameter bit ALLOW_LANE1_ALONE=1'b0
) (
    input logic clk, input logic rst_n,
    input logic valid0, input logic [4:0] rs1_0, input logic rs1_0_used,
    input logic [4:0] rs2_0, input logic rs2_0_used, input logic [4:0] rd0,
    input logic writes0, input logic [XLEN-1:0] a0, input logic [XLEN-1:0] b0,
    input alu_op_e op0,
    input logic valid1, input logic [4:0] rs1_1, input logic rs1_1_used,
    input logic [4:0] rs2_1, input logic rs2_1_used, input logic [4:0] rd1,
    input logic writes1, input logic [XLEN-1:0] a1, input logic [XLEN-1:0] b1,
    input alu_op_e op1,
    output logic issue0, output logic issue1,
    output logic commit_valid0, output logic [4:0] commit_rd0,
    output logic [XLEN-1:0] commit_data0,
    output logic commit_valid1, output logic [4:0] commit_rd1,
    output logic [XLEN-1:0] commit_data1
);
  logic [XLEN-1:0] result0, result1;
  logic valid0_q, valid1_q;
  logic [4:0] rd0_q, rd1_q;
  logic [XLEN-1:0] data0_q, data1_q;

  alu alu0(.op(op0),.a(a0),.b(b0),.result(result0));
  alu alu1(.op(op1),.a(a1),.b(b1),.result(result1));

  issue_scoreboard #(.REG_COUNT(REG_COUNT),.ALLOW_LANE1_ALONE(ALLOW_LANE1_ALONE)) scoreboard(
    .clk(clk),.rst_n(rst_n),
    .valid0(valid0),.rs1_0(rs1_0),.rs1_0_used(rs1_0_used),
    .rs2_0(rs2_0),.rs2_0_used(rs2_0_used),.rd0(rd0),.writes0(writes0),
    .valid1(valid1),.rs1_1(rs1_1),.rs1_1_used(rs1_1_used),
    .rs2_1(rs2_1),.rs2_1_used(rs2_1_used),.rd1(rd1),.writes1(writes1),
    .issue0(issue0),.issue1(issue1),
    .commit_valid0(valid0_q),.commit_rd0(rd0_q),
    .commit_valid1(valid1_q),.commit_rd1(rd1_q));

  assign commit_valid0=valid0_q;
  assign commit_rd0=rd0_q;
  assign commit_data0=data0_q;
  assign commit_valid1=valid1_q;
  assign commit_rd1=rd1_q;
  assign commit_data1=data1_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid0_q<=1'b0; valid1_q<=1'b0; rd0_q<='0; rd1_q<='0;
      data0_q<='0; data1_q<='0;
    end else begin
      valid0_q<=issue0; valid1_q<=issue1;
      rd0_q<=rd0; rd1_q<=rd1;
      data0_q<=result0; data1_q<=result1;
    end
  end
`ifndef SYNTHESIS
  a_lane1_in_order: assert property (@(posedge clk) disable iff (!rst_n)
    (ALLOW_LANE1_ALONE || !issue1 || issue0));
  a_commit_follows_issue0: assert property (@(posedge clk) disable iff (!rst_n)
    commit_valid0 |-> $past(issue0));
  a_commit_follows_issue1: assert property (@(posedge clk) disable iff (!rst_n)
    commit_valid1 |-> $past(issue1));
`endif
endmodule : dual_issue_alu
