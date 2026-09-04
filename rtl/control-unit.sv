// ============================================================================
// control_unit -- the RV32I instruction decoder.
//
// Purely combinational. This is the ONLY module that knows the ISA encoding;
// everything downstream sees the microarchitecture types in decoded_t.
// ============================================================================
module control_unit
  import rv32i_pkg::*;
(
    input  logic [XLEN-1:0] instr,
    output decoded_t        d
);

  opcode_e            opcode;
  logic [2:0]         funct3;
  logic               alt;      // funct7[5]: the ADD/SUB, SRL/SRA discriminator
  logic [11:0]        imm12;

  assign opcode = opcode_e'(instr[OPCODE_MSB:OPCODE_LSB]);
  assign funct3 = instr[FUNCT3_MSB:FUNCT3_LSB];
  assign alt    = instr[ALT_OP_BIT];
  assign imm12  = instr[31:20];

  // funct7 must be exactly F7_BASE or F7_ALT for the shift/arith ops.
  logic funct7_ok;
  assign funct7_ok = (instr[FUNCT7_MSB:FUNCT7_LSB] == F7_BASE) ||
                     (instr[FUNCT7_MSB:FUNCT7_LSB] == F7_ALT);

  // Only ADD/SUB and SRL/SRA read bit 30. There is no SUBI, so for ADDI that
  // bit is immediate data and must be masked off.
  logic alt_legal_reg, alt_legal_imm;
  assign alt_legal_reg = (funct3 == F3_ADD_SUB) || (funct3 == F3_SR);
  assign alt_legal_imm = (funct3 == F3_SR);

  always_comb begin
    // Defaults: a well-formed NOP that writes nothing.
    d           = '0;
    d.illegal   = 1'b0;
    d.alu_op    = ALU_ADD;
    d.a_sel     = A_RS1;
    d.b_sel     = B_IMM;
    d.imm_sel   = IMM_NONE;
    d.br_op     = BR_NONE;
    d.mem_op    = MEM_W;
    d.mem_read  = 1'b0;
    d.mem_write = 1'b0;
    d.wb_sel    = WB_ALU;
    d.rd_we     = 1'b0;
    d.halt      = 1'b0;
    d.rd_addr   = instr[RD_MSB:RD_LSB];
    d.rs1_addr  = instr[RS1_MSB:RS1_LSB];
    d.rs2_addr  = instr[RS2_MSB:RS2_LSB];

    unique case (opcode)

      // -- U-type ------------------------------------------------------------
      OP_LUI: begin
        d.alu_op  = ALU_PASS_B;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_U;
        d.wb_sel  = WB_ALU;
        d.rd_we   = 1'b1;
      end

      OP_AUIPC: begin
        d.alu_op  = ALU_ADD;
        d.a_sel   = A_PC;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_U;
        d.wb_sel  = WB_ALU;
        d.rd_we   = 1'b1;
      end

      // -- jumps: ALU computes the target, writeback takes pc+4 --------------
      OP_JAL: begin
        d.alu_op  = ALU_ADD;
        d.a_sel   = A_PC;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_J;
        d.br_op   = BR_JAL;
        d.wb_sel  = WB_PC4;
        d.rd_we   = 1'b1;
      end

      OP_JALR: begin
        d.alu_op  = ALU_ADD;
        d.a_sel   = A_RS1;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_I;
        d.br_op   = BR_JALR;
        d.wb_sel  = WB_PC4;
        d.rd_we   = 1'b1;
        d.illegal = (funct3 != F3_JALR);
      end

      // -- B-type: ALU computes pc+imm, branch_unit decides ------------------
      OP_BRANCH: begin
        d.alu_op  = ALU_ADD;
        d.a_sel   = A_PC;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_B;
        d.br_op   = br_op_e'({1'b1, funct3});
        d.rd_we   = 1'b0;
        // funct3 010 and 011 are reserved in BRANCH.
        d.illegal = (funct3 == 3'b010) || (funct3 == 3'b011);
      end

      // -- loads -------------------------------------------------------------
      OP_LOAD: begin
        d.alu_op   = ALU_ADD;
        d.a_sel    = A_RS1;
        d.b_sel    = B_IMM;
        d.imm_sel  = IMM_I;
        d.mem_read = 1'b1;
        d.mem_op   = mem_op_e'(funct3);
        d.wb_sel   = WB_MEM;
        d.rd_we    = 1'b1;
        d.illegal  = (funct3 == 3'b011) || (funct3 == 3'b110) ||
                     (funct3 == 3'b111);
      end

      // -- stores ------------------------------------------------------------
      OP_STORE: begin
        d.alu_op    = ALU_ADD;
        d.a_sel     = A_RS1;
        d.b_sel     = B_IMM;
        d.imm_sel   = IMM_S;
        d.mem_write = 1'b1;
        d.mem_op    = mem_op_e'(funct3);
        d.rd_we     = 1'b0;
        d.illegal   = (funct3 != F3_SB) && (funct3 != F3_SH) &&
                      (funct3 != F3_SW);
      end

      // -- register-immediate ------------------------------------------------
      OP_IMM: begin
        d.alu_op  = alu_op_e'({alt & alt_legal_imm, funct3});
        d.a_sel   = A_RS1;
        d.b_sel   = B_IMM;
        d.imm_sel = IMM_I;
        d.wb_sel  = WB_ALU;
        d.rd_we   = 1'b1;
        // SLLI/SRLI/SRAI carry a funct7; the other OP_IMM forms do not.
        d.illegal = ((funct3 == F3_SLL) || (funct3 == F3_SR)) && !funct7_ok;
      end

      // -- register-register -------------------------------------------------
      OP_REG: begin
        d.alu_op  = alu_op_e'({alt & alt_legal_reg, funct3});
        d.a_sel   = A_RS1;
        d.b_sel   = B_RS2;
        d.wb_sel  = WB_ALU;
        d.rd_we   = 1'b1;
        d.illegal = !funct7_ok || (alt && !alt_legal_reg);
      end

      // -- FENCE: architecturally a no-op on a single in-order core ----------
      OP_MISC_MEM: begin
        d.rd_we = 1'b0;
      end

      // -- SYSTEM: baseline handles ECALL/EBREAK as halt ---------------------
      OP_SYSTEM: begin
        d.rd_we   = 1'b0;
        d.halt    = (funct3 == F3_PRIV) &&
                    ((imm12 == SYS_ECALL) || (imm12 == SYS_EBREAK));
        d.illegal = !d.halt;   // CSR ops arrive with Zicsr
      end

      default: begin
        d.illegal = 1'b1;
      end
    endcase
  end

endmodule : control_unit
