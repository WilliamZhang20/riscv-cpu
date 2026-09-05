// ============================================================================
// cpu_core -- bus-facing five-stage RV32I core.
//
// Instruction fetches and data accesses use mem_if master ports and may stall
// independently. This is the single CPU-core definition used by the system.
// ============================================================================
module cpu_core
  import rv32i_pkg::*;
#(
    parameter logic [XLEN-1:0] RESET_PC = 32'h0000_0000
)(
    input logic clk,
    input logic rst_n,

    mem_if.master imem,
    mem_if.master dmem,

    output logic halted,
    output logic trap_illegal,
    output logic retire,
    output logic [XLEN-1:0] retire_pc,
    output logic [XLEN-1:0] retire_instr
);

  typedef struct packed {
    logic            valid;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;
  } if_id_reg_t;

  typedef struct packed {
    logic            valid;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;
    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;
    logic [4:0]      rs1_addr;
    logic [4:0]      rs2_addr;
    logic [4:0]      rd_addr;
    logic [XLEN-1:0] imm;
    decoded_t        d;
  } id_ex_reg_t;

  typedef struct packed {
    logic            valid;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] rs2_data;
    logic [4:0]      rs2_addr;
    logic [4:0]      rd_addr;
    decoded_t        d;
  } ex_mem_reg_t;

  typedef struct packed {
    logic            valid;
    logic            bus_error;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] load_data;
    logic [4:0]      rd_addr;
    decoded_t        d;
  } mem_wb_reg_t;

  if_id_reg_t  if_id_q, if_id_n;
  id_ex_reg_t  id_ex_q, id_ex_n;
  ex_mem_reg_t ex_mem_q, ex_mem_n;
  mem_wb_reg_t mem_wb_q, mem_wb_n;

  logic [XLEN-1:0] pc_q;
  logic            halted_q, trap_illegal_q;

  // --------------------------------------------------------------------------
  // Instruction fetch transaction state
  // --------------------------------------------------------------------------
  logic            fetch_pending_q;
  logic            fetch_kill_q;
  logic            fetch_hold_q;
  logic [XLEN-1:0] fetch_pc_q;
  logic [XLEN-1:0] fetch_hold_pc_q;
  logic [XLEN-1:0] fetch_hold_instr_q;
  logic            imem_req_fire;
  logic            imem_rsp_fire;

  logic            ex_redirect;
  logic [XLEN-1:0] ex_target;

  assign imem.req_valid = !halted_q && !fetch_pending_q && !fetch_hold_q &&
                          !if_id_q.valid &&
                          !mem_stall && !frontend_stop && !ex_redirect;
  assign imem.req_addr  = pc_q;
  assign imem.req_write = 1'b0;
  assign imem.req_wdata = '0;
  assign imem.req_be    = 4'b1111;
  // A one-entry response buffer lets the frontend accept a response while a
  // data access is stalled, without losing the instruction or deadlocking a
  // shared interconnect serving both ports.
  assign imem.rsp_ready = !fetch_hold_q;

  assign imem_req_fire = imem.req_valid && imem.req_ready;
  assign imem_rsp_fire = imem.rsp_valid && imem.rsp_ready;

  // --------------------------------------------------------------------------
  // Decode and register file
  // --------------------------------------------------------------------------
  decoded_t        d;
  logic [XLEN-1:0] rs1_data, rs2_data, imm;
  logic            rf_we;
  logic [XLEN-1:0] rf_wdata;

  control_unit u_dec (
      .instr (if_id_q.instr),
      .d     (d)
  );

  imm_gen u_imm (
      .instr (if_id_q.instr),
      .sel   (d.imm_sel),
      .imm    (imm)
  );

  register_file u_rf (
      .clk      (clk),
      .rs1_addr (d.rs1_addr),
      .rs1_data (rs1_data),
      .rs2_addr (d.rs2_addr),
      .rs2_data (rs2_data),
      .rd_we    (rf_we),
      .rd_addr  (mem_wb_q.rd_addr),
      .rd_data  (rf_wdata)
  );

  // --------------------------------------------------------------------------
  // Execute and forwarding
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] alu_a, alu_b, alu_result;
  logic [XLEN-1:0] ex_rs1_data, ex_rs2_data;
  logic [XLEN-1:0] ex_mem_fwd_data;
  logic [XLEN-1:0] mem_store_data;
  logic            branch_take;
  logic            wb_fwd_valid;

  assign wb_fwd_valid = mem_wb_q.valid && mem_wb_q.d.rd_we &&
                        !mem_wb_q.d.illegal && !mem_wb_q.d.halt &&
                        !mem_wb_q.bus_error && !halted_q;
  assign ex_mem_fwd_data = (ex_mem_q.d.wb_sel == WB_PC4)
                         ? ex_mem_q.pc + 32'd4 : ex_mem_q.alu_result;

  always_comb begin
    ex_rs1_data = id_ex_q.rs1_data;
    if (ex_mem_q.valid && ex_mem_q.d.rd_we && !ex_mem_q.d.mem_read &&
        ex_mem_q.rd_addr != '0 && ex_mem_q.rd_addr == id_ex_q.rs1_addr)
      ex_rs1_data = ex_mem_fwd_data;
    else if (wb_fwd_valid && mem_wb_q.rd_addr != '0 &&
             mem_wb_q.rd_addr == id_ex_q.rs1_addr)
      ex_rs1_data = rf_wdata;

    ex_rs2_data = id_ex_q.rs2_data;
    if (ex_mem_q.valid && ex_mem_q.d.rd_we && !ex_mem_q.d.mem_read &&
        ex_mem_q.rd_addr != '0 && ex_mem_q.rd_addr == id_ex_q.rs2_addr)
      ex_rs2_data = ex_mem_fwd_data;
    else if (wb_fwd_valid && mem_wb_q.rd_addr != '0 &&
             mem_wb_q.rd_addr == id_ex_q.rs2_addr)
      ex_rs2_data = rf_wdata;
  end

  // WB -> MEM forwarding is needed when a store reaches the memory stage
  // while its source value is still in WB.
  always_comb begin
    mem_store_data = ex_mem_q.rs2_data;
    if (ex_mem_q.valid && ex_mem_q.d.mem_write && wb_fwd_valid &&
        mem_wb_q.rd_addr != '0 &&
        mem_wb_q.rd_addr == ex_mem_q.rs2_addr)
      mem_store_data = rf_wdata;
  end

  always_comb begin
    unique case (id_ex_q.d.a_sel)
      A_PC:    alu_a = id_ex_q.pc;
      A_ZERO:  alu_a = '0;
      default: alu_a = ex_rs1_data;
    endcase
  end

  assign alu_b = (id_ex_q.d.b_sel == B_IMM) ? id_ex_q.imm : ex_rs2_data;

  alu u_alu (
      .op     (id_ex_q.d.alu_op),
      .a      (alu_a),
      .b      (alu_b),
      .result (alu_result)
  );

  branch_unit u_br (
      .op       (id_ex_q.d.br_op),
      .rs1_data (ex_rs1_data),
      .rs2_data (ex_rs2_data),
      .take     (branch_take)
  );

  assign ex_redirect = id_ex_q.valid && !id_ex_q.d.illegal &&
                       !id_ex_q.d.halt && branch_take && !mem_stall;
  assign ex_target = (id_ex_q.d.br_op == BR_JALR)
                   ? {alu_result[XLEN-1:1], 1'b0} : alu_result;

  // --------------------------------------------------------------------------
  // Data transaction state
  // --------------------------------------------------------------------------
  logic            mem_access;
  logic            mem_pending_q, mem_done_q, mem_error_q;
  logic [XLEN-1:0] mem_load_data_q;
  logic            mem_stall;
  logic            dmem_req_fire, dmem_rsp_fire;
  logic [1:0]      byte_off;
  logic [7:0]      load_byte;
  logic [15:0]     load_half;

  assign mem_access = ex_mem_q.valid &&
                      (ex_mem_q.d.mem_read || ex_mem_q.d.mem_write);
  assign mem_stall = mem_access && !mem_done_q;

  assign dmem.req_valid = mem_access && !mem_pending_q && !mem_done_q &&
                          !halted_q;
  assign dmem.req_addr  = ex_mem_q.alu_result;
  assign dmem.req_write = ex_mem_q.d.mem_write;
  always_comb begin
    unique case (ex_mem_q.d.mem_op)
      MEM_B, MEM_BU:
        dmem.req_be = 4'b0001 << ex_mem_q.alu_result[1:0];
      MEM_H, MEM_HU:
        dmem.req_be = ex_mem_q.alu_result[1] ? 4'b1100 : 4'b0011;
      default:
        dmem.req_be = 4'b1111;
    endcase
  end

  always_comb begin
    unique case (ex_mem_q.d.mem_op)
      MEM_B, MEM_BU: dmem.req_wdata = {4{mem_store_data[7:0]}};
      MEM_H, MEM_HU: dmem.req_wdata = {2{mem_store_data[15:0]}};
      default:       dmem.req_wdata = mem_store_data;
    endcase
  end
  assign dmem.rsp_ready = mem_pending_q;

  assign dmem_req_fire = dmem.req_valid && dmem.req_ready;
  assign dmem_rsp_fire = dmem.rsp_valid && dmem.rsp_ready;

  assign byte_off   = ex_mem_q.alu_result[1:0];
  assign load_byte  = dmem.rsp_rdata[8*byte_off +: 8];
  assign load_half  = byte_off[1] ? dmem.rsp_rdata[31:16]
                                  : dmem.rsp_rdata[15:0];

  always_comb begin
    unique case (ex_mem_q.d.mem_op)
      MEM_B:   mem_load_data = {{24{load_byte[7]}}, load_byte};
      MEM_BU:  mem_load_data = {24'b0, load_byte};
      MEM_H:   mem_load_data = {{16{load_half[15]}}, load_half};
      MEM_HU:  mem_load_data = {16'b0, load_half};
      default: mem_load_data = dmem.rsp_rdata;
    endcase
  end

  logic [XLEN-1:0] mem_load_data;

  // --------------------------------------------------------------------------
  // Writeback and control
  // --------------------------------------------------------------------------
  always_comb begin
    unique case (mem_wb_q.d.wb_sel)
      WB_MEM:  rf_wdata = mem_wb_q.load_data;
      WB_PC4:  rf_wdata = mem_wb_q.pc + 32'd4;
      default: rf_wdata = mem_wb_q.alu_result;
    endcase
  end

  assign rf_we = mem_wb_q.valid && mem_wb_q.d.rd_we &&
                 !mem_wb_q.d.illegal && !mem_wb_q.d.halt &&
                 !mem_wb_q.bus_error && !halted_q;

  logic frontend_stop;
  assign frontend_stop = halted_q ||
                         (if_id_q.valid && (d.illegal || d.halt)) ||
                         (id_ex_q.valid &&
                          (id_ex_q.d.illegal || id_ex_q.d.halt)) ||
                         (ex_mem_q.valid &&
                          (ex_mem_q.d.illegal || ex_mem_q.d.halt)) ||
                         (mem_wb_q.valid &&
                          (mem_wb_q.d.illegal || mem_wb_q.d.halt));

  // --------------------------------------------------------------------------
  // Pipeline next-state logic
  // --------------------------------------------------------------------------
  always_comb begin
    if_id_n  = if_id_q;
    id_ex_n  = '0;
    ex_mem_n = ex_mem_q;
    mem_wb_n = '0;

    if (mem_stall) begin
      // Keep the blocked memory operation and the instruction behind it in
      // place. Older WB state is allowed to drain through the bubble.
      id_ex_n = id_ex_q;
      ex_mem_n = ex_mem_q;
    end else begin
      ex_mem_n.valid      = id_ex_q.valid;
      ex_mem_n.pc         = id_ex_q.pc;
      ex_mem_n.instr      = id_ex_q.instr;
      ex_mem_n.alu_result = alu_result;
      ex_mem_n.rs2_data   = ex_rs2_data;
      ex_mem_n.rs2_addr   = id_ex_q.rs2_addr;
      ex_mem_n.rd_addr    = id_ex_q.rd_addr;
      ex_mem_n.d          = id_ex_q.d;

      mem_wb_n.valid      = ex_mem_q.valid;
      mem_wb_n.bus_error  = mem_error_q;
      mem_wb_n.pc         = ex_mem_q.pc;
      mem_wb_n.instr      = ex_mem_q.instr;
      mem_wb_n.alu_result = ex_mem_q.alu_result;
      mem_wb_n.load_data  = mem_load_data_q;
      mem_wb_n.rd_addr    = ex_mem_q.rd_addr;
      mem_wb_n.d          = ex_mem_q.d;

      if (ex_redirect) begin
        if_id_n = '0;
        id_ex_n = '0;
      end else if (if_id_q.valid) begin
        id_ex_n.valid    = 1'b1;
        id_ex_n.pc       = if_id_q.pc;
        id_ex_n.instr    = if_id_q.instr;
        id_ex_n.rs1_data = rs1_data;
        id_ex_n.rs2_data = rs2_data;
        id_ex_n.rs1_addr = d.rs1_addr;
        id_ex_n.rs2_addr = d.rs2_addr;
        id_ex_n.rd_addr  = d.rd_addr;
        id_ex_n.imm      = imm;
        id_ex_n.d        = d;
        if_id_n = '0;
      end

      if (!ex_redirect && !frontend_stop && !if_id_q.valid && fetch_hold_q) begin
        if_id_n.valid = 1'b1;
        if_id_n.pc    = fetch_hold_pc_q;
        if_id_n.instr = fetch_hold_instr_q;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_q            <= RESET_PC;
      if_id_q         <= '0;
      id_ex_q         <= '0;
      ex_mem_q        <= '0;
      mem_wb_q        <= '0;
      halted_q        <= 1'b0;
      trap_illegal_q  <= 1'b0;
      fetch_pending_q <= 1'b0;
      fetch_kill_q    <= 1'b0;
      fetch_hold_q    <= 1'b0;
      fetch_pc_q      <= '0;
      fetch_hold_pc_q <= '0;
      fetch_hold_instr_q <= '0;
      mem_pending_q   <= 1'b0;
      mem_done_q      <= 1'b0;
      mem_error_q     <= 1'b0;
      mem_load_data_q <= '0;
    end else begin
      if_id_q  <= if_id_n;
      id_ex_q  <= id_ex_n;
      ex_mem_q <= ex_mem_n;
      mem_wb_q <= mem_wb_n;

      if (mem_wb_q.valid &&
          (mem_wb_q.d.halt || mem_wb_q.d.illegal || mem_wb_q.bus_error)) begin
        halted_q       <= 1'b1;
        trap_illegal_q <= mem_wb_q.d.illegal;
      end

      if (imem_req_fire) begin
        fetch_pending_q <= 1'b1;
        fetch_pc_q      <= pc_q;
        pc_q            <= pc_q + 32'd4;
      end

      if (imem_rsp_fire) begin
        fetch_pending_q <= 1'b0;
        fetch_kill_q    <= 1'b0;
        if (ex_redirect || frontend_stop || fetch_kill_q) begin
          fetch_hold_q <= 1'b0;
        end else begin
          fetch_hold_q      <= 1'b1;
          fetch_hold_pc_q   <= fetch_pc_q;
          fetch_hold_instr_q <= imem.rsp_error ? 32'b0 : imem.rsp_rdata;
        end
      end else if (ex_redirect) begin
        pc_q         <= ex_target;
        fetch_kill_q <= fetch_pending_q;
      end

      if (fetch_hold_q && !mem_stall && !ex_redirect && !frontend_stop &&
          !if_id_q.valid)
        fetch_hold_q <= 1'b0;

      if (!mem_stall) begin
        mem_pending_q <= 1'b0;
        mem_done_q    <= 1'b0;
        mem_error_q   <= 1'b0;
      end

      if (dmem_req_fire)
        mem_pending_q <= 1'b1;

      if (dmem_rsp_fire) begin
        mem_pending_q   <= 1'b0;
        mem_done_q      <= 1'b1;
        mem_error_q     <= dmem.rsp_error;
        mem_load_data_q <= mem_load_data;
      end
    end
  end

  assign halted       = halted_q;
  assign trap_illegal = trap_illegal_q;
  assign retire       = mem_wb_q.valid && !mem_wb_q.d.halt &&
                        !mem_wb_q.d.illegal && !mem_wb_q.bus_error &&
                        !halted_q;
  assign retire_pc    = mem_wb_q.pc;
  assign retire_instr = mem_wb_q.instr;

endmodule : cpu_core
