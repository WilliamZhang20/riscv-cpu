// ============================================================================
// branch_unit -- evaluates the branch condition.
//
// Its own comparator rather than reusing ALU flags: in the pipelined version
// the ALU is busy computing the branch *target* in the same cycle this has to
// decide whether the branch is taken.
// ============================================================================
module branch_unit
  import rv32i_pkg::*;
(
    input  br_op_e          op,
    input  logic [XLEN-1:0] rs1_data,
    input  logic [XLEN-1:0] rs2_data,

    output logic            take
);

  always_comb begin
    unique case (op)
      BR_JAL, BR_JALR: take = 1'b1;                                  // unconditional
      BR_EQ:           take = (rs1_data == rs2_data);
      BR_NE:           take = (rs1_data != rs2_data);
      BR_LT:           take = ($signed(rs1_data) <  $signed(rs2_data));
      BR_GE:           take = ($signed(rs1_data) >= $signed(rs2_data));
      BR_LTU:          take = (rs1_data <  rs2_data);
      BR_GEU:          take = (rs1_data >= rs2_data);
      default:         take = 1'b0;
    endcase
  end

endmodule : branch_unit
