// In-order two-wide issue scoreboard.
// The scoreboard tracks destination registers of issued instructions until commit.
// Lane 1 can issue only when lane 0 issues, preserving program order.
module issue_scoreboard #(
    parameter int unsigned REG_COUNT=32,
    parameter bit ALLOW_LANE1_ALONE=1'b0
) (
    input logic clk, input logic rst_n,
    input logic valid0, input logic [4:0] rs1_0, input logic rs1_0_used,
    input logic [4:0] rs2_0, input logic rs2_0_used, input logic [4:0] rd0,
    input logic writes0,
    input logic valid1, input logic [4:0] rs1_1, input logic rs1_1_used,
    input logic [4:0] rs2_1, input logic rs2_1_used, input logic [4:0] rd1,
    input logic writes1,
    output logic issue0, output logic issue1,
    input logic commit_valid0, input logic [4:0] commit_rd0,
    input logic commit_valid1, input logic [4:0] commit_rd1
);
  logic busy_q [REG_COUNT];
  logic lane0_src_ready, lane1_src_ready;
  logic lane1_dep_lane0;
  function automatic logic reg_ready(input logic used, input logic [4:0] regno);
    if (!used || regno == 0) reg_ready = 1'b1;
    else reg_ready = !busy_q[regno];
  endfunction
  always_comb begin
    lane0_src_ready = reg_ready(rs1_0_used,rs1_0) &&
                      reg_ready(rs2_0_used,rs2_0);
    issue0 = valid0 && lane0_src_ready &&
             !(writes0 && rd0 != 0 && busy_q[rd0]);
    lane1_dep_lane0 = valid0 && issue0 && writes0 && rd0 != 0 &&
                      ((rs1_1_used && rs1_1 == rd0) ||
                       (rs2_1_used && rs2_1 == rd0) ||
                       (writes1 && rd1 == rd0));
    lane1_src_ready = reg_ready(rs1_1_used,rs1_1) &&
                      reg_ready(rs2_1_used,rs2_1);
    issue1 = valid1 && (issue0 || (ALLOW_LANE1_ALONE && !valid0)) &&
             lane1_src_ready && !lane1_dep_lane0 &&
             !(writes1 && rd1 != 0 && busy_q[rd1]);
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<REG_COUNT;i++) busy_q[i] <= 1'b0;
    end else begin
      if (commit_valid0 && commit_rd0 != 0) busy_q[commit_rd0] <= 1'b0;
      if (commit_valid1 && commit_rd1 != 0) busy_q[commit_rd1] <= 1'b0;
      if (issue0 && writes0 && rd0 != 0) busy_q[rd0] <= 1'b1;
      if (issue1 && writes1 && rd1 != 0) busy_q[rd1] <= 1'b1;
    end
  end
`ifndef SYNTHESIS
  a_lane1_requires_lane0: assert property (@(posedge clk) disable iff (!rst_n) (ALLOW_LANE1_ALONE || !issue1 || issue0));
`endif
endmodule : issue_scoreboard
