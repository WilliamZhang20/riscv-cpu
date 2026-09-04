// ============================================================================
// imm_gen -- extracts and sign-extends the immediate for every RV32I format.
//
// The scrambled bit orders below are not arbitrary: RISC-V places the sign bit
// at instr[31] in every format and keeps each immediate bit in a near-constant
// position, so the sign extender and the muxes stay cheap.
// ============================================================================
module imm_gen
  import rv32i_pkg::*;
(
    input  logic [XLEN-1:0] instr,
    input  imm_sel_e        sel,
    output logic [XLEN-1:0] imm
);

  always_comb begin
    unique case (sel)
      IMM_I:   imm = {{20{instr[31]}}, instr[31:20]};
      IMM_S:   imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      IMM_B:   imm = {{19{instr[31]}}, instr[31], instr[7],
                      instr[30:25], instr[11:8], 1'b0};
      IMM_U:   imm = {instr[31:12], 12'b0};
      IMM_J:   imm = {{11{instr[31]}}, instr[31], instr[19:12],
                      instr[20], instr[30:21], 1'b0};
      IMM_Z:   imm = {27'b0, instr[19:15]};
      default: imm = '0;
    endcase
  end

endmodule : imm_gen
