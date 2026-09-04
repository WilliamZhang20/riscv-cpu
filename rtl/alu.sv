// ============================================================================
// alu -- integer ALU for the EX stage.
//
// Purely combinational: no clk, no reset, no state.
// Takes alu_op_e, never an opcode -- the decoder owns the ISA-to-control map.
// ============================================================================
module alu
  import rv32i_pkg::*;
(
    input  alu_op_e         op,
    input  logic [XLEN-1:0] a,
    input  logic [XLEN-1:0] b,

    output logic [XLEN-1:0] result
);

  // RV32I shifts use only the low 5 bits of the shift operand; the upper bits
  // are ignored, not an error (spec Vol I, sec. 2.4).
  logic [4:0] shamt;
  assign shamt = b[4:0];

  always_comb begin
    unique case (op)
      ALU_ADD:    result = a + b;
      ALU_SUB:    result = a - b;
      ALU_SLL:    result = a << shamt;
      ALU_SLT:    result = {31'b0, ($signed(a) <  $signed(b))};
      ALU_SLTU:   result = {31'b0, (a < b)};
      ALU_XOR:    result = a ^ b;
      ALU_SRL:    result = a >> shamt;
      ALU_SRA:    result = $unsigned($signed(a) >>> shamt);
      ALU_OR:     result = a | b;
      ALU_AND:    result = a & b;
      ALU_PASS_B: result = b;
      default:    result = '0;
    endcase
  end

endmodule : alu
