// ============================================================================
// program_counter -- the architectural PC.
//
// Held (not incremented) while en is low, so the multicycle FSM can spend
// several cycles on one instruction and advance only at retire.
// ============================================================================
module program_counter
  import rv32i_pkg::*;
#(
    parameter logic [XLEN-1:0] RESET_PC = 32'h0000_0000
)(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            en,
    input  logic [XLEN-1:0] next_pc,

    output logic [XLEN-1:0] pc
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)   pc <= RESET_PC;
    else if (en)  pc <= next_pc;
  end

endmodule : program_counter
