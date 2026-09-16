// Full RV32I two-wide in-order composition root.
//
// The frontend fetches two instructions together.  Independent instructions
// can retire in the same cycle; a same-pair RAW dependency consumes lane 0
// first and holds lane 1 until the producer has written the register file.
// Memory operations are deliberately serialized through the single dmem port,
// while branches and jumps retire in order and redirect the next fetch pair.
module dual_issue_rv32i_core
  import rv32i_pkg::*;
#(
    parameter logic [XLEN-1:0] RESET_PC = 32'h0,
    parameter logic [XLEN-1:0] TRAP_VECTOR = 32'h100
) (
    input logic clk, input logic rst_n, input logic irq,
    mem_if.master imem0, mem_if.master imem1, mem_if.master dmem,
    output logic halted, output logic trap_illegal, output logic interrupt_taken,
    output logic retire_valid0, output logic [XLEN-1:0] retire_pc0,
    output logic [XLEN-1:0] retire_instr0, output logic [4:0] retire_rd0,
    output logic [XLEN-1:0] retire_data0,
    output logic retire_valid1, output logic [XLEN-1:0] retire_pc1,
    output logic [XLEN-1:0] retire_instr1, output logic [4:0] retire_rd1,
    output logic [XLEN-1:0] retire_data1,
    output logic [63:0] cycle_count, output logic [63:0] retired_count
);
  logic start_fetch, fetch_busy, pair_valid, pair_ready, pair_error;
  logic [XLEN-1:0] pair_pc, instr0, instr1;
  logic lane0_done_q, started_q, mem_pending_q, mem_lane_q;
  logic [XLEN-1:0] pc_q, mepc_q, mtvec_q;
  logic halted_q, trap_illegal_q;
  logic [XLEN-1:0] mem_addr_q;
  logic mem_error_q;

  decoded_t d0, d1;
  logic [XLEN-1:0] imm0, imm1, rs1_0, rs2_0, rs1_1, rs2_1;
  logic [XLEN-1:0] result0, result1;
  logic [XLEN-1:0] op1_0, op2_0, op1_1, op2_1;
  logic branch_take0, branch_take1;
  logic issue0, issue1, lane0_mem, lane1_mem;
  logic lane0_control, lane1_control, lane0_serial, lane1_bad, lane0_bad;
  logic [XLEN-1:0] csr_old0, csr_old1, csr_src0, csr_src1, csr_new0, csr_new1;
  logic same_pair_raw;
  logic mem_req_candidate, mem_rsp_fire;
  logic commit0_now, commit1_now;
  logic [XLEN-1:0] commit_data0_now, commit_data1_now;
  logic redirect_now;
  logic [XLEN-1:0] redirect_target;
  logic rf0_we, rf1_we;

  assign start_fetch = !started_q && !halted_q;

  dual_fetch_pair fetch (
      .clk(clk), .rst_n(rst_n), .start(start_fetch), .start_pc(pc_q),
      .busy(fetch_busy), .pair_valid(pair_valid), .pair_ready(pair_ready),
      .pair_pc(pair_pc), .instr0(instr0), .instr1(instr1),
      .pair_error(pair_error), .imem0(imem0), .imem1(imem1));

  control_unit dec0(.instr(instr0), .d(d0));
  control_unit dec1(.instr(instr1), .d(d1));
  imm_gen immgen0(.instr(instr0), .sel(d0.imm_sel), .imm(imm0));
  imm_gen immgen1(.instr(instr1), .sel(d1.imm_sel), .imm(imm1));

  register_file_2wide #(.READ_BYPASS(1'b0)) rf (
      .clk(clk),
      .rs1_0_addr(d0.rs1_addr), .rs1_0_data(rs1_0),
      .rs2_0_addr(d0.rs2_addr), .rs2_0_data(rs2_0),
      .rs1_1_addr(d1.rs1_addr), .rs1_1_data(rs1_1),
      .rs2_1_addr(d1.rs2_addr), .rs2_1_data(rs2_1),
      .rd0_we(rf0_we), .rd0_addr(d0.rd_addr), .rd0_data(commit_data0_now),
      .rd1_we(rf1_we), .rd1_addr(d1.rd_addr), .rd1_data(commit_data1_now));

  assign lane0_bad = d0.illegal || d0.halt;
  assign lane1_bad = d1.illegal || d1.halt;
  assign lane0_mem = d0.mem_read || d0.mem_write;
  assign lane1_mem = d1.mem_read || d1.mem_write;
  assign lane0_control = d0.mret || (d0.br_op != BR_NONE);
  assign lane0_serial = lane0_mem || lane0_control || d0.csr;
  assign lane1_control = d1.mret || (d1.br_op != BR_NONE);

  // Lane 1 waits for lane 0 whenever it consumes a value produced by lane 0.
  // This is the scoreboard's same-cycle dependency rule in the composition
  // root; ALU results are also bypassed when both lanes issue together.
  assign same_pair_raw = (d0.rd_we && d0.rd_addr != '0) &&
                         ((d1.rs1_addr == d0.rd_addr) ||
                          (d1.rs2_addr == d0.rd_addr));
  assign issue0 = pair_valid && !lane0_done_q && !lane0_bad;
  assign issue1 = pair_valid && !lane1_bad &&
                  (lane0_done_q ||
                   (issue0 && !lane0_serial && !same_pair_raw));

  always_comb begin
    op1_0 = rs1_0;
    op2_0 = rs2_0;
    op1_1 = rs1_1;
    op2_1 = rs2_1;
    if (issue0 && d0.rd_we && d0.rd_addr != '0 && d0.rd_addr == d1.rs1_addr)
      op1_1 = result0;
    if (issue0 && d0.rd_we && d0.rd_addr != '0 && d0.rd_addr == d1.rs2_addr)
      op2_1 = result0;
  end

  always_comb begin
    unique case (d0.csr_addr)
      12'h305: csr_old0 = mtvec_q;
      12'h341: csr_old0 = mepc_q;
      12'h342: csr_old0 = 32'b0;
      default: csr_old0 = 32'b0;
    endcase
    unique case (d1.csr_addr)
      12'h305: csr_old1 = mtvec_q;
      12'h341: csr_old1 = mepc_q;
      12'h342: csr_old1 = 32'b0;
      default: csr_old1 = 32'b0;
    endcase
    csr_src0 = (d0.imm_sel == IMM_Z) ? imm0 : op1_0;
    csr_src1 = (d1.imm_sel == IMM_Z) ? imm1 : op1_1;
    unique case (d0.csr_funct3)
      F3_CSRRW, F3_CSRRWI: csr_new0 = csr_src0;
      F3_CSRRS, F3_CSRRSI: csr_new0 = csr_old0 | csr_src0;
      F3_CSRRC, F3_CSRRCI: csr_new0 = csr_old0 & ~csr_src0;
      default: csr_new0 = csr_old0;
    endcase
    unique case (d1.csr_funct3)
      F3_CSRRW, F3_CSRRWI: csr_new1 = csr_src1;
      F3_CSRRS, F3_CSRRSI: csr_new1 = csr_old1 | csr_src1;
      F3_CSRRC, F3_CSRRCI: csr_new1 = csr_old1 & ~csr_src1;
      default: csr_new1 = csr_old1;
    endcase
  end

  alu alu_lane0(.op(d0.alu_op), .a((d0.a_sel == A_PC) ? pair_pc :
                                   ((d0.a_sel == A_ZERO) ? '0 : op1_0)),
                 .b((d0.b_sel == B_IMM) ? imm0 : op2_0), .result(result0));
  alu alu_lane1(.op(d1.alu_op), .a((d1.a_sel == A_PC) ? pair_pc + 32'd4 :
                                   ((d1.a_sel == A_ZERO) ? '0 : op1_1)),
                 .b((d1.b_sel == B_IMM) ? imm1 : op2_1), .result(result1));

  branch_unit br0(.op(d0.br_op), .rs1_data(op1_0), .rs2_data(op2_0),
                  .take(branch_take0));
  branch_unit br1(.op(d1.br_op), .rs1_data(op1_1), .rs2_data(op2_1),
                  .take(branch_take1));

  assign mem_req_candidate = !mem_pending_q &&
      ((issue0 && lane0_mem && !lane0_done_q) ||
       (issue1 && lane1_mem && lane0_done_q));
  assign dmem.req_valid = mem_req_candidate && !halted_q;
  assign dmem.req_addr = lane0_done_q ? result1 : result0;
  assign dmem.req_write = lane0_done_q ? d1.mem_write : d0.mem_write;
  always_comb begin
    dmem.req_be = 4'b1111;
    if (lane0_done_q ? (d1.mem_op == MEM_B || d1.mem_op == MEM_BU) :
                       (d0.mem_op == MEM_B || d0.mem_op == MEM_BU))
      dmem.req_be = 4'b0001 << dmem.req_addr[1:0];
    else if (lane0_done_q ? (d1.mem_op == MEM_H || d1.mem_op == MEM_HU) :
                            (d0.mem_op == MEM_H || d0.mem_op == MEM_HU))
      dmem.req_be = dmem.req_addr[1] ? 4'b1100 : 4'b0011;
    dmem.req_wdata = lane0_done_q ? {4{op2_1[7:0]}} : {4{op2_0[7:0]}};
    if (lane0_done_q ? (d1.mem_op == MEM_H || d1.mem_op == MEM_HU) :
                       (d0.mem_op == MEM_H || d0.mem_op == MEM_HU))
      dmem.req_wdata = lane0_done_q ? {2{op2_1[15:0]}} : {2{op2_0[15:0]}};
    else if (!(lane0_done_q ? (d1.mem_op == MEM_B || d1.mem_op == MEM_BU) :
                              (d0.mem_op == MEM_B || d0.mem_op == MEM_BU)))
      dmem.req_wdata = lane0_done_q ? op2_1 : op2_0;
  end
  assign dmem.rsp_ready = mem_pending_q;
  assign mem_rsp_fire = dmem.rsp_valid && dmem.rsp_ready;

  function automatic logic [XLEN-1:0] extend_load(
      input mem_op_e op, input logic [XLEN-1:0] data,
      input logic [1:0] offset);
    logic [7:0] b;
    logic [15:0] h;
    begin
      b = data[8*offset +: 8];
      h = offset[1] ? data[31:16] : data[15:0];
      unique case (op)
        MEM_B: extend_load = {{24{b[7]}}, b};
        MEM_BU: extend_load = {24'b0, b};
        MEM_H: extend_load = {{16{h[15]}}, h};
        MEM_HU: extend_load = {16'b0, h};
        default: extend_load = data;
      endcase
    end
  endfunction

  always_comb begin
    commit0_now = issue0 && !mem_pending_q && !lane0_mem;
    commit1_now = issue1 && !mem_pending_q && !lane1_mem;
    commit_data0_now = d0.csr ? csr_old0 : ((d0.wb_sel == WB_PC4) ? pair_pc + 32'd4 : result0);
    commit_data1_now = d1.csr ? csr_old1 : ((d1.wb_sel == WB_PC4) ? pair_pc + 32'd8 : result1);
    if (mem_rsp_fire && !mem_lane_q && d0.mem_read)
      commit_data0_now = extend_load(d0.mem_op, dmem.rsp_rdata, mem_addr_q[1:0]);
    if (mem_rsp_fire && mem_lane_q && d1.mem_read)
      commit_data1_now = extend_load(d1.mem_op, dmem.rsp_rdata, mem_addr_q[1:0]);
    if (mem_rsp_fire && !mem_lane_q) commit0_now = !dmem.rsp_error;
    if (mem_rsp_fire && mem_lane_q) commit1_now = !dmem.rsp_error;
  end
  assign rf0_we = commit0_now && d0.rd_we && !d0.illegal && !d0.halt;
  assign rf1_we = commit1_now && d1.rd_we && !d1.illegal && !d1.halt;

  assign redirect_now = (commit0_now && lane0_control &&
                         (d0.mret || d0.br_op == BR_JAL || branch_take0)) ||
                        (commit1_now && lane1_control &&
                         (d1.mret || d1.br_op == BR_JAL || branch_take1));
  assign redirect_target = (commit0_now && lane0_control) ?
      (d0.mret ? mepc_q : ((d0.br_op == BR_JALR) ?
                           {result0[31:1],1'b0} : result0)) :
      (d1.mret ? mepc_q : ((d1.br_op == BR_JALR) ?
                           {result1[31:1],1'b0} : result1));

  // Release a pair only after all instructions before it have retired.  A
  // dependency deliberately leaves lane 1 in the held pair for the next
  // cycle; a memory operation releases it only after its response.  A
  // serial lane 0 (branch/CSR) that does not redirect must likewise hold
  // lane 1 for the next cycle -- releasing the pair would skip lane 1's
  // instruction (it lives at pair_pc+4, before pair_pc+8).  A redirecting
  // lane 0 flushes lane 1, which is off the taken path.
  always_comb begin
    pair_ready = 1'b0;
    if (pair_valid) begin
      if (pair_error || lane0_bad)
        pair_ready = 1'b1;
      else if (mem_rsp_fire)
        pair_ready = mem_lane_q;
      else if (lane1_bad)
        pair_ready = 1'b1;
      else if (lane0_done_q)
        pair_ready = !lane1_mem;
      else if (lane0_mem)
        pair_ready = 1'b0;
      else if (lane0_serial)
        pair_ready = redirect_now;
      else if (issue1)
        pair_ready = 1'b1;
      else if (!same_pair_raw)
        pair_ready = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      started_q <= 1'b0; lane0_done_q <= 1'b0; mem_pending_q <= 1'b0;
      mem_lane_q <= 1'b0; mem_addr_q <= '0; mem_error_q <= 1'b0;
      pc_q <= RESET_PC; mtvec_q <= TRAP_VECTOR; mepc_q <= '0;
      halted_q <= 1'b0; trap_illegal_q <= 1'b0; interrupt_taken <= 1'b0;
      retire_valid0 <= 1'b0; retire_valid1 <= 1'b0;
      retire_pc0 <= '0; retire_pc1 <= '0; retire_instr0 <= '0; retire_instr1 <= '0;
      retire_rd0 <= '0; retire_rd1 <= '0; retire_data0 <= '0; retire_data1 <= '0;
      cycle_count <= '0; retired_count <= '0;
    end else begin
      cycle_count <= cycle_count + 64'd1;
      retire_valid0 <= 1'b0; retire_valid1 <= 1'b0; interrupt_taken <= 1'b0;

      if (start_fetch) started_q <= 1'b1;
      if (pair_ready) begin
        started_q <= 1'b0;
        lane0_done_q <= 1'b0;
        pc_q <= redirect_now ? redirect_target : pair_pc + 32'd8;
      end
      if (!lane0_done_q && issue0 && !lane0_mem && !mem_pending_q &&
          !redirect_now && !lane1_bad && !issue1 &&
          (same_pair_raw || lane0_serial))
        lane0_done_q <= 1'b1;

      if (mem_req_candidate && dmem.req_valid && dmem.req_ready) begin
        mem_pending_q <= 1'b1;
        mem_lane_q <= lane0_done_q;
        mem_addr_q <= dmem.req_addr;
      end
      if (mem_rsp_fire) begin
        mem_pending_q <= 1'b0;
        mem_error_q <= dmem.rsp_error;
        if (dmem.rsp_error) begin
          halted_q <= 1'b1;
          trap_illegal_q <= 1'b0;
        end else if (!mem_lane_q) begin
          lane0_done_q <= 1'b1;
        end
      end

      if (pair_valid && (pair_error || lane0_bad ||
          ((lane0_done_q || issue0) && lane1_bad))) begin
        halted_q <= 1'b1;
        trap_illegal_q <= pair_error || d0.illegal ||
                          ((lane0_done_q || issue0) && d1.illegal);
      end
      if (irq && !mem_pending_q && !pair_valid && !halted_q) begin
        pc_q <= mtvec_q; mepc_q <= pc_q; interrupt_taken <= 1'b1;
        started_q <= 1'b0;
      end

      if (commit0_now && d0.csr) begin
        unique case (d0.csr_addr)
          12'h305: mtvec_q <= csr_new0;
          12'h341: mepc_q <= csr_new0;
          default: ;
        endcase
      end
      if (commit1_now && d1.csr) begin
        unique case (d1.csr_addr)
          12'h305: mtvec_q <= csr_new1;
          12'h341: mepc_q <= csr_new1;
          default: ;
        endcase
      end

      if (commit0_now) begin
        retire_valid0 <= 1'b1; retire_pc0 <= pair_pc; retire_instr0 <= instr0;
        retire_rd0 <= d0.rd_addr; retire_data0 <= commit_data0_now;
      end
      if (commit1_now) begin
        retire_valid1 <= 1'b1; retire_pc1 <= pair_pc + 32'd4;
        retire_instr1 <= instr1; retire_rd1 <= d1.rd_addr;
        retire_data1 <= commit_data1_now;
      end
      if (commit0_now || commit1_now)
        retired_count <= retired_count + (commit0_now ? 64'd1 : 64'd0) +
                         (commit1_now ? 64'd1 : 64'd0);
      if (pair_valid && lane0_bad) halted_q <= 1'b1;
    end
  end

  assign halted = halted_q;
  assign trap_illegal = trap_illegal_q;

`ifndef SYNTHESIS
  a_lane_order: assert property (@(posedge clk) disable iff (!rst_n)
    issue1 |-> issue0 || lane0_done_q)
    else $error("dual issue issued lane 1 before lane 0");
  a_two_wide_only_independent: assert property (@(posedge clk) disable iff (!rst_n)
    retire_valid0 && retire_valid1 |-> !same_pair_raw);
`endif
endmodule : dual_issue_rv32i_core
