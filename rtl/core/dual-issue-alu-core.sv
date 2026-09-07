// Runnable Phase 5 ALU-core composition root.
//
// This root repeatedly fetches adjacent instruction pairs and advances the PC
// after the second instruction retires. It intentionally accepts only the
// side-effect-free ALU subset implemented by dual_issue_core_slice; memory,
// branch, CSR, and trap retirement belong in the next widened pipeline shell.
module dual_issue_alu_core #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter logic [ADDR_W-1:0] RESET_PC = '0
) (
    input logic clk,
    input logic rst_n,
    output logic [ADDR_W-1:0] fetch_pc,
    output logic fetch_active,
    output logic retire_valid0,
    output logic [4:0] retire_rd0,
    output logic [DATA_W-1:0] retire_data0,
    output logic retire_valid1,
    output logic [4:0] retire_rd1,
    output logic [DATA_W-1:0] retire_data1,
    mem_if.master imem0,
    mem_if.master imem1
);
  logic start_q;
  logic [ADDR_W-1:0] pc_q;
  logic slice_busy, pair_valid;
  logic pair_ready;
  logic [ADDR_W-1:0] pair_pc;
  logic [DATA_W-1:0] instr0, instr1;
  logic issue0, issue1;

  assign fetch_pc = pc_q;
  assign fetch_active = slice_busy || pair_valid || start_q;
  assign pair_ready = issue0 && issue1;

  dual_issue_core_slice #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) slice (
      .clk(clk), .rst_n(rst_n), .fetch_start(start_q), .fetch_pc(pc_q),
      .fetch_busy(slice_busy), .pair_valid(pair_valid), .pair_ready(pair_ready),
      .pair_pc(pair_pc), .instr0(instr0), .instr1(instr1),
      .issue0(issue0), .issue1(issue1),
      .commit_valid0(retire_valid0), .commit_rd0(retire_rd0),
      .commit_data0(retire_data0), .commit_valid1(retire_valid1),
      .commit_rd1(retire_rd1), .commit_data1(retire_data1),
      .imem0(imem0), .imem1(imem1));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_q <= 1'b0;
      pc_q <= RESET_PC;
    end else begin
      start_q <= 1'b0;
      // The slice retains a dependent lane 1 and emits its commit one cycle
      // later; lane 1 commit is therefore the unambiguous pair completion.
      if (retire_valid1)
        pc_q <= pc_q + ADDR_W'(8);
      if (!slice_busy && !pair_valid && !retire_valid1)
        start_q <= 1'b1;
    end
  end
`ifndef SYNTHESIS
  a_pc_advances_by_pair: assert property (@(posedge clk) disable iff (!rst_n)
    retire_valid1 |=> $past(fetch_pc) + ADDR_W'(8) == fetch_pc);
`endif
endmodule : dual_issue_alu_core
