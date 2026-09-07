// Two-request instruction fetch pair for the 2-wide front end.
// Each lane has an independent response buffer; the pair is released only
// after both PC and PC+4 responses are available.
module dual_fetch_pair #(
    parameter int unsigned ADDR_W=32,
    parameter int unsigned DATA_W=32
) (
    input logic clk, input logic rst_n,
    input logic start, input logic [ADDR_W-1:0] start_pc,
    output logic busy, output logic pair_valid, input logic pair_ready,
    output logic [ADDR_W-1:0] pair_pc,
    output logic [DATA_W-1:0] instr0, output logic [DATA_W-1:0] instr1,
    output logic pair_error,
    mem_if.master imem0, mem_if.master imem1
);
  logic active_q, pending0_q, pending1_q, valid0_q, valid1_q;
  logic [ADDR_W-1:0] pc_q;
  logic [DATA_W-1:0] data0_q, data1_q;
  logic error0_q, error1_q;
  assign busy=active_q;
  assign pair_valid=active_q && valid0_q && valid1_q;
  assign pair_pc=pc_q; assign instr0=data0_q; assign instr1=data1_q;
  assign pair_error=error0_q || error1_q;
  assign imem0.req_valid=active_q && !pending0_q && !valid0_q;
  assign imem0.req_addr=pc_q; assign imem0.req_write=1'b0;
  assign imem0.req_wdata='0; assign imem0.req_be={DATA_W/8{1'b1}};
  assign imem0.rsp_ready=active_q && !valid0_q;
  assign imem1.req_valid=active_q && !pending1_q && !valid1_q;
  assign imem1.req_addr=pc_q+ADDR_W'(4); assign imem1.req_write=1'b0;
  assign imem1.req_wdata='0; assign imem1.req_be={DATA_W/8{1'b1}};
  assign imem1.rsp_ready=active_q && !valid1_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_q<=0; pending0_q<=0; pending1_q<=0; valid0_q<=0; valid1_q<=0;
      pc_q<='0; data0_q<='0; data1_q<='0; error0_q<=0; error1_q<=0;
    end else begin
      if (!active_q && start) begin
        active_q<=1; pc_q<=start_pc; pending0_q<=0; pending1_q<=0;
        valid0_q<=0; valid1_q<=0; error0_q<=0; error1_q<=0;
      end else if (active_q) begin
        if (imem0.req_valid && imem0.req_ready) pending0_q<=1;
        if (imem1.req_valid && imem1.req_ready) pending1_q<=1;
        if (imem0.rsp_valid && imem0.rsp_ready) begin
          pending0_q<=0; valid0_q<=1; data0_q<=imem0.rsp_rdata; error0_q<=imem0.rsp_error;
        end
        if (imem1.rsp_valid && imem1.rsp_ready) begin
          pending1_q<=0; valid1_q<=1; data1_q<=imem1.rsp_rdata; error1_q<=imem1.rsp_error;
        end
        if (pair_valid && pair_ready) begin
          active_q<=0; valid0_q<=0; valid1_q<=0;
        end
      end
    end
  end
`ifndef SYNTHESIS
  a_pair_requires_two_responses: assert property (@(posedge clk) disable iff (!rst_n)
    pair_valid |-> valid0_q && valid1_q);
  a_pair_stable_until_consumed: assert property (@(posedge clk) disable iff (!rst_n)
    pair_valid && !pair_ready |=> $stable(pair_pc) && $stable(instr0) && $stable(instr1));
`endif
endmodule : dual_fetch_pair
