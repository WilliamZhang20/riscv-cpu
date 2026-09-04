// ============================================================================
// rv32i_pkg -- RV32I instruction encoding + core microarchitecture control types
//
// Two namespaces live here and must not leak into each other:
//   1. ISA encoding    -- fixed by the RISC-V spec. Transcribed, never invented.
//   2. Control encoding -- ours to choose. Only the decoder maps (1) onto (2).
//
// Reference: "The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA",
// Chapter 2 (RV32I Base Integer Instruction Set) and Chapter 34 (opcode maps).
// ============================================================================
package rv32i_pkg;

  // --------------------------------------------------------------------------
  // Architectural parameters
  // --------------------------------------------------------------------------
  localparam int unsigned XLEN       = 32;  // register / datapath width
  localparam int unsigned REG_ADDR_W = 5;   // log2(NUM_REGS)
  localparam int unsigned NUM_REGS   = 32;  // x0 .. x31

  localparam logic [XLEN-1:0] NOP_INSTR = 32'h0000_0013;  // addi x0, x0, 0

  // --------------------------------------------------------------------------
  // Instruction field positions
  //
  //   31        25 24    20 19    15 14  12 11     7 6      0
  //  +------------+--------+--------+------+--------+--------+
  //  |   funct7   |  rs2   |  rs1   |funct3|   rd   | opcode |  R-type
  //  +------------+--------+--------+------+--------+--------+
  //  |    imm[11:0]        |  rs1   |funct3|   rd   | opcode |  I-type
  //  +------------+--------+--------+------+--------+--------+
  //  | imm[11:5]  |  rs2   |  rs1   |funct3|imm[4:0]| opcode |  S-type
  //  +------------+--------+--------+------+--------+--------+
  //  |imm[12|10:5]|  rs2   |  rs1   |funct3|imm[4:1|11]|opcode| B-type
  //  +------------+--------+--------+------+--------+--------+
  //  |          imm[31:12]                 |   rd   | opcode |  U-type
  //  +------------+--------+--------+------+--------+--------+
  //  |     imm[20|10:1|11|19:12]           |   rd   | opcode |  J-type
  //  +------------+--------+--------+------+--------+--------+
  // --------------------------------------------------------------------------
  localparam int OPCODE_MSB = 6,  OPCODE_LSB = 0;
  localparam int RD_MSB     = 11, RD_LSB     = 7;
  localparam int FUNCT3_MSB = 14, FUNCT3_LSB = 12;
  localparam int RS1_MSB    = 19, RS1_LSB    = 15;
  localparam int RS2_MSB    = 24, RS2_LSB    = 20;
  localparam int FUNCT7_MSB = 31, FUNCT7_LSB = 25;

  // Bit 30 is funct7[5]: the ADD/SUB and SRL/SRA discriminator.
  localparam int ALT_OP_BIT = 30;

  // ==========================================================================
  // (1) ISA ENCODING -- fixed by the spec
  // ==========================================================================

  // -- opcode, instr[6:0]. Bits [1:0] are 2'b11 for all 32-bit instructions. --
  typedef enum logic [6:0] {
    OP_LOAD     = 7'b000_0011,  // LB LH LW LBU LHU
    OP_MISC_MEM = 7'b000_1111,  // FENCE (FENCE.I with Zifencei)
    OP_IMM      = 7'b001_0011,  // ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
    OP_AUIPC    = 7'b001_0111,  // AUIPC
    OP_STORE    = 7'b010_0011,  // SB SH SW
    OP_REG      = 7'b011_0011,  // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
    OP_LUI      = 7'b011_0111,  // LUI
    OP_BRANCH   = 7'b110_0011,  // BEQ BNE BLT BGE BLTU BGEU
    OP_JALR     = 7'b110_0111,  // JALR
    OP_JAL      = 7'b110_1111,  // JAL
    OP_SYSTEM   = 7'b111_0011   // ECALL EBREAK (CSR* with Zicsr)
  } opcode_e;

  // -- funct3 for OP_REG / OP_IMM --
  localparam logic [2:0] F3_ADD_SUB = 3'b000;  // ADD, SUB (funct7[5]), ADDI
  localparam logic [2:0] F3_SLL     = 3'b001;  // SLL, SLLI
  localparam logic [2:0] F3_SLT     = 3'b010;  // SLT, SLTI
  localparam logic [2:0] F3_SLTU    = 3'b011;  // SLTU, SLTIU
  localparam logic [2:0] F3_XOR     = 3'b100;  // XOR, XORI
  localparam logic [2:0] F3_SR      = 3'b101;  // SRL, SRA (funct7[5]), SRLI, SRAI
  localparam logic [2:0] F3_OR      = 3'b110;  // OR, ORI
  localparam logic [2:0] F3_AND     = 3'b111;  // AND, ANDI

  // -- funct3 for OP_BRANCH. 3'b010 and 3'b011 are reserved. --
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;

  // -- funct3 for OP_LOAD --
  localparam logic [2:0] F3_LB  = 3'b000;
  localparam logic [2:0] F3_LH  = 3'b001;
  localparam logic [2:0] F3_LW  = 3'b010;
  localparam logic [2:0] F3_LBU = 3'b100;
  localparam logic [2:0] F3_LHU = 3'b101;

  // -- funct3 for OP_STORE --
  localparam logic [2:0] F3_SB = 3'b000;
  localparam logic [2:0] F3_SH = 3'b001;
  localparam logic [2:0] F3_SW = 3'b010;

  // -- funct3 for OP_JALR (only legal value) --
  localparam logic [2:0] F3_JALR = 3'b000;

  // -- funct3 for OP_MISC_MEM --
  localparam logic [2:0] F3_FENCE   = 3'b000;
  localparam logic [2:0] F3_FENCE_I = 3'b001;  // Zifencei

  // -- funct3 for OP_SYSTEM. F3_PRIV selects on the imm12 field below. --
  localparam logic [2:0] F3_PRIV    = 3'b000;
  localparam logic [2:0] F3_CSRRW   = 3'b001;  // Zicsr
  localparam logic [2:0] F3_CSRRS   = 3'b010;
  localparam logic [2:0] F3_CSRRC   = 3'b011;
  localparam logic [2:0] F3_CSRRWI  = 3'b101;
  localparam logic [2:0] F3_CSRRSI  = 3'b110;
  localparam logic [2:0] F3_CSRRCI  = 3'b111;

  // -- instr[31:20] for OP_SYSTEM with funct3 == F3_PRIV --
  localparam logic [11:0] SYS_ECALL  = 12'h000;
  localparam logic [11:0] SYS_EBREAK = 12'h001;
  localparam logic [11:0] SYS_MRET   = 12'h302;
  localparam logic [11:0] SYS_WFI    = 12'h105;

  // -- funct7 --
  localparam logic [6:0] F7_BASE = 7'b000_0000;  // ADD, SRL, SLLI, SRLI
  localparam logic [6:0] F7_ALT  = 7'b010_0000;  // SUB, SRA, SRAI

  // ==========================================================================
  // (2) CONTROL ENCODING -- ours to choose
  //
  // The numeric values below are deliberate, not arbitrary: they are
  //   {funct7[5], funct3}
  // so the decoder for OP_REG / OP_IMM collapses to a concatenation instead of
  // a ten-arm case statement, while the ALU still reads as named symbols.
  //
  //   alu_op = alu_op_e'({ instr[ALT_OP_BIT] & is_alt_legal, funct3 });
  //
  // where is_alt_legal gates on OP_REG, or OP_IMM with funct3 == F3_SR --
  // there is no SUBI, so for ADDI bit 30 is part of the immediate.
  // ==========================================================================
  typedef enum logic [3:0] {
    ALU_ADD    = 4'b0000,
    ALU_SLL    = 4'b0001,
    ALU_SLT    = 4'b0010,
    ALU_SLTU   = 4'b0011,
    ALU_XOR    = 4'b0100,
    ALU_SRL    = 4'b0101,
    ALU_OR     = 4'b0110,
    ALU_AND    = 4'b0111,
    ALU_SUB    = 4'b1000,
    ALU_SRA    = 4'b1101,
    ALU_PASS_B = 4'b1010   // LUI: forward operand b unchanged
  } alu_op_e;

  // -- ALU operand sources --
  typedef enum logic [1:0] {
    A_RS1  = 2'd0,
    A_PC   = 2'd1,  // AUIPC, JAL target
    A_ZERO = 2'd2   // reserved: shift-from-zero idioms
  } alu_a_sel_e;

  typedef enum logic [0:0] {
    B_RS2 = 1'd0,
    B_IMM = 1'd1
  } alu_b_sel_e;

  // -- Immediate format select --
  typedef enum logic [2:0] {
    IMM_NONE = 3'd0,
    IMM_I    = 3'd1,
    IMM_S    = 3'd2,
    IMM_B    = 3'd3,
    IMM_U    = 3'd4,
    IMM_J    = 3'd5,
    IMM_Z    = 3'd6   // CSR zero-extended uimm[4:0], Zicsr
  } imm_sel_e;

  // -- Branch / jump condition. Encoded {is_conditional, funct3} so the six
  //    conditional forms fall straight out of funct3. --
  typedef enum logic [3:0] {
    BR_NONE = 4'b0000,
    BR_JAL  = 4'b0001,  // unconditional, target = pc + imm_j
    BR_JALR = 4'b0010,  // unconditional, target = (rs1 + imm_i) & ~32'h1
    BR_EQ   = 4'b1000,
    BR_NE   = 4'b1001,
    BR_LT   = 4'b1100,
    BR_GE   = 4'b1101,
    BR_LTU  = 4'b1110,
    BR_GEU  = 4'b1111
  } br_op_e;

  // -- Memory access width + sign extension. Encoded as the load funct3;
  //    stores use only MEM_B / MEM_H / MEM_W. --
  typedef enum logic [2:0] {
    MEM_B  = 3'b000,
    MEM_H  = 3'b001,
    MEM_W  = 3'b010,
    MEM_BU = 3'b100,
    MEM_HU = 3'b101
  } mem_op_e;

  // -- Writeback source --
  typedef enum logic [1:0] {
    WB_ALU = 2'd0,
    WB_MEM = 2'd1,
    WB_PC4 = 2'd2,  // JAL / JALR link value
    WB_CSR = 2'd3   // Zicsr
  } wb_sel_e;


  // --------------------------------------------------------------------------
  // Decoded instruction -- the control unit's entire output. Bundling it as a
  // packed struct means adding a control signal touches one line here instead
  // of every module port list it has to travel through.
  // --------------------------------------------------------------------------
  typedef struct packed {
    logic                  illegal;    // no legal decode for this word
    alu_op_e               alu_op;
    alu_a_sel_e            a_sel;
    alu_b_sel_e            b_sel;
    imm_sel_e              imm_sel;
    br_op_e                br_op;
    mem_op_e               mem_op;
    logic                  mem_read;
    logic                  mem_write;
    wb_sel_e               wb_sel;
    logic                  rd_we;
    logic                  halt;       // ECALL / EBREAK
    logic [REG_ADDR_W-1:0] rd_addr;
    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
  } decoded_t;

endpackage : rv32i_pkg
