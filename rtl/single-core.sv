// ============================================================================
// cpu_core -- baseline multicycle RV32I core.
//
// One instruction in flight, walked through five states:
//
//   IF  : imem_addr = pc, latch the fetched word into ir
//   ID  : decode ir, read rs1/rs2, generate imm, latch operands
//   EX  : ALU result and branch decision -> alu_q, take_q, target_q
//   MEM : data-memory access (stores commit here, loads latch into load_q)
//   WB  : register write and PC update
//
// This is deliberately NOT pipelined. Every state boundary here becomes a
// pipeline register later; the datapath and control below do not change when
// it is cut, which is the whole reason to build this shape first.
//
// Memories are asynchronous-read "magic" memories -- no stall handshake yet.
// ============================================================================
module cpu_core
  import rv32i_pkg::*;
#(
    parameter logic [XLEN-1:0] RESET_PC = 32'h0000_0000
)(
    input  logic            clk,
    input  logic            rst_n,

    // instruction memory: asynchronous read
    output logic [XLEN-1:0] imem_addr,
    input  logic [XLEN-1:0] imem_rdata,

    // data memory: asynchronous read, synchronous byte-enabled write
    output logic [XLEN-1:0] dmem_addr,
    output logic            dmem_we,
    output logic [3:0]      dmem_be,
    output logic [XLEN-1:0] dmem_wdata,
    input  logic [XLEN-1:0] dmem_rdata,

    // status / trace
    output logic            halted,
    output logic            trap_illegal,
    output logic            retire,          // pulses for one cycle in WB
    output logic [XLEN-1:0] retire_pc,
    output logic [XLEN-1:0] retire_instr
);

  // --------------------------------------------------------------------------
  // FSM
  // --------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IF  = 3'd0,
    S_ID  = 3'd1,
    S_EX  = 3'd2,
    S_MEM = 3'd3,
    S_WB  = 3'd4,
    S_HLT = 3'd5
  } state_e;

  state_e state, state_n;

  // --------------------------------------------------------------------------
  // Sequential state carried between states
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] ir;         // fetched instruction
  logic [XLEN-1:0] rs1_q;      // operands latched at end of ID
  logic [XLEN-1:0] rs2_q;
  logic [XLEN-1:0] imm_q;
  logic [XLEN-1:0] alu_q;      // ALU result latched at end of EX
  logic            take_q;     // branch/jump decision latched at end of EX
  logic [XLEN-1:0] target_q;   // branch/jump target latched at end of EX
  logic [XLEN-1:0] load_q;     // formatted load data latched at end of MEM
  logic            illegal_q;

  // --------------------------------------------------------------------------
  // PC
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] pc, next_pc;
  logic            pc_en;

  assign pc_en = (state == S_WB) && !illegal_q;

  // Jump targets: JALR clears bit 0 of rs1+imm (spec Vol I, sec. 2.5.1);
  // JAL and branches are inherently even.
  assign next_pc = take_q ? target_q : (pc + 32'd4);

  program_counter #(.RESET_PC(RESET_PC)) u_pc (
      .clk     (clk),
      .rst_n   (rst_n),
      .en      (pc_en),
      .next_pc (next_pc),
      .pc      (pc)
  );

  // --------------------------------------------------------------------------
  // IF
  // --------------------------------------------------------------------------
  assign imem_addr = pc;

  // --------------------------------------------------------------------------
  // ID: decode + regfile + immediate
  // --------------------------------------------------------------------------
  decoded_t        d;
  logic [XLEN-1:0] rs1_data, rs2_data, imm;
  logic            rf_we;
  logic [XLEN-1:0] rf_wdata;

  control_unit u_dec (
      .instr (ir),
      .d     (d)
  );

  imm_gen u_imm (
      .instr (ir),
      .sel   (d.imm_sel),
      .imm   (imm)
  );

  register_file u_rf (
      .clk      (clk),
      .rs1_addr (d.rs1_addr),
      .rs1_data (rs1_data),
      .rs2_addr (d.rs2_addr),
      .rs2_data (rs2_data),
      .rd_we    (rf_we),
      .rd_addr  (d.rd_addr),
      .rd_data  (rf_wdata)
  );

  // --------------------------------------------------------------------------
  // EX: ALU + branch condition
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] alu_a, alu_b, alu_result;
  logic            branch_take;

  always_comb begin
    unique case (d.a_sel)
      A_PC:    alu_a = pc;
      A_ZERO:  alu_a = '0;
      default: alu_a = rs1_q;
    endcase
  end

  assign alu_b = (d.b_sel == B_IMM) ? imm_q : rs2_q;

  alu u_alu (
      .op     (d.alu_op),
      .a      (alu_a),
      .b      (alu_b),
      .result (alu_result)
  );

  branch_unit u_br (
      .op       (d.br_op),
      .rs1_data (rs1_q),
      .rs2_data (rs2_q),
      .take     (branch_take)
  );

  // --------------------------------------------------------------------------
  // MEM: address, byte enables, store alignment, load formatting
  // --------------------------------------------------------------------------
  logic [1:0] byte_off;
  assign byte_off = alu_q[1:0];

  // Full byte address on the bus: the memory ignores the low two bits, but the
  // testbench (and any real slave) needs them to check alignment.
  assign dmem_addr = alu_q;
  assign dmem_we   = (state == S_MEM) && d.mem_write && !illegal_q;

  always_comb begin
    unique case (d.mem_op)
      MEM_B:   dmem_be = 4'b0001 << byte_off;
      MEM_H:   dmem_be = byte_off[1] ? 4'b1100 : 4'b0011;
      default: dmem_be = 4'b1111;                          // MEM_W
    endcase
  end

  // Replicate the store data into the lane the byte enables select.
  always_comb begin
    unique case (d.mem_op)
      MEM_B:   dmem_wdata = {4{rs2_q[7:0]}};
      MEM_H:   dmem_wdata = {2{rs2_q[15:0]}};
      default: dmem_wdata = rs2_q;                         // MEM_W
    endcase
  end

  logic [7:0]  load_byte;
  logic [15:0] load_half;
  assign load_byte = dmem_rdata[8*byte_off   +: 8];
  assign load_half = byte_off[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

  logic [XLEN-1:0] load_data;
  always_comb begin
    unique case (d.mem_op)
      MEM_B:   load_data = {{24{load_byte[7]}},  load_byte};
      MEM_BU:  load_data = {24'b0,               load_byte};
      MEM_H:   load_data = {{16{load_half[15]}}, load_half};
      MEM_HU:  load_data = {16'b0,               load_half};
      default: load_data = dmem_rdata;                     // MEM_W
    endcase
  end

  // --------------------------------------------------------------------------
  // WB
  // --------------------------------------------------------------------------
  always_comb begin
    unique case (d.wb_sel)
      WB_MEM:  rf_wdata = load_q;
      WB_PC4:  rf_wdata = pc + 32'd4;
      default: rf_wdata = alu_q;                           // WB_ALU, WB_CSR
    endcase
  end

  assign rf_we = (state == S_WB) && d.rd_we && !illegal_q;

  // --------------------------------------------------------------------------
  // Next-state logic
  // --------------------------------------------------------------------------
  always_comb begin
    unique case (state)
      S_IF:    state_n = S_ID;
      S_ID:    state_n = (d.illegal || d.halt) ? S_HLT : S_EX;
      S_EX:    state_n = S_MEM;
      S_MEM:   state_n = S_WB;
      S_WB:    state_n = S_IF;
      default: state_n = S_HLT;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= S_IF;
      ir        <= NOP_INSTR;
      rs1_q     <= '0;
      rs2_q     <= '0;
      imm_q     <= '0;
      alu_q     <= '0;
      take_q    <= 1'b0;
      target_q  <= '0;
      load_q    <= '0;
      illegal_q <= 1'b0;
    end else begin
      state <= state_n;

      if (state == S_IF) begin
        ir <= imem_rdata;
      end

      if (state == S_ID) begin
        rs1_q     <= rs1_data;
        rs2_q     <= rs2_data;
        imm_q     <= imm;
        illegal_q <= d.illegal;
      end

      if (state == S_EX) begin
        alu_q    <= alu_result;
        take_q   <= branch_take;
        target_q <= (d.br_op == BR_JALR) ? {alu_result[XLEN-1:1], 1'b0}
                                         : alu_result;
      end

      if (state == S_MEM) begin
        load_q <= load_data;
      end
    end
  end

  // --------------------------------------------------------------------------
  // Status / trace
  // --------------------------------------------------------------------------
  assign halted       = (state == S_HLT);
  assign trap_illegal = (state == S_HLT) && d.illegal;
  assign retire       = (state == S_WB);
  assign retire_pc    = pc;
  assign retire_instr = ir;

endmodule : cpu_core
