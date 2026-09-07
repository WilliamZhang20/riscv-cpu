// Connected Phase 5 composition root.
// Branch, memory, trap, and retirement policy remain outside this ALU slice;
// pair_ready is the explicit contract for the eventual full pipeline.
module dual_issue_core_slice #(
    parameter int unsigned ADDR_W=32,
    parameter int unsigned DATA_W=32
) (
    input logic clk, input logic rst_n,
    input logic fetch_start, input logic [ADDR_W-1:0] fetch_pc,
    output logic fetch_busy, output logic pair_valid,
    input logic pair_ready, output logic [ADDR_W-1:0] pair_pc,
    output logic [DATA_W-1:0] instr0, output logic [DATA_W-1:0] instr1,
    output logic issue0, output logic issue1,
    output logic commit_valid0, output logic [4:0] commit_rd0,
    output logic [DATA_W-1:0] commit_data0,
    output logic commit_valid1, output logic [4:0] commit_rd1,
    output logic [DATA_W-1:0] commit_data1,
    mem_if.master imem0, mem_if.master imem1
);
  logic lane0_consumed_q;
  logic decode_valid0, consume_pair;
  assign decode_valid0 = pair_valid && !lane0_consumed_q;
  assign consume_pair = pair_valid &&
                        ((lane0_consumed_q && issue1) ||
                         (!lane0_consumed_q && issue0 && issue1));
  dual_fetch_pair #(.ADDR_W(ADDR_W),.DATA_W(DATA_W)) fetch(
    .clk(clk),.rst_n(rst_n),.start(fetch_start),.start_pc(fetch_pc),
    .busy(fetch_busy),.pair_valid(pair_valid),.pair_ready((pair_ready && issue0 && issue1) || consume_pair),
    .pair_pc(pair_pc),.instr0(instr0),.instr1(instr1),.pair_error(),
    .imem0(imem0),.imem1(imem1));
  dual_issue_decode_execute #(.ALLOW_LANE1_ALONE(1'b1)) decode_execute(
    .clk(clk),.rst_n(rst_n),.valid0(decode_valid0),.pc0(pair_pc),.instr0(instr0),
    .valid1(pair_valid),.pc1(pair_pc+ADDR_W'(4)),.instr1(instr1),
    .issue0(issue0),.issue1(issue1),.commit_valid0(commit_valid0),
    .commit_rd0(commit_rd0),.commit_data0(commit_data0),
    .commit_valid1(commit_valid1),.commit_rd1(commit_rd1),.commit_data1(commit_data1));
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) lane0_consumed_q <= 1'b0;
    else if (consume_pair) lane0_consumed_q <= 1'b0;
    else if (pair_valid && !lane0_consumed_q && issue0 && !issue1)
      lane0_consumed_q <= 1'b1;
  end
endmodule : dual_issue_core_slice
