// Decoder-facing wrapper for the two-wide integer execution shell.
// Memory, branch, CSR, and trap instructions are held for the later widened
// pipeline; this stage only issues side-effect-free ALU instructions.
module dual_issue_decode_execute
  import rv32i_pkg::*;
#(parameter bit ALLOW_LANE1_ALONE=1'b0)
(
    input logic clk, input logic rst_n,
    input logic valid0, input logic [XLEN-1:0] pc0, input logic [XLEN-1:0] instr0,
    input logic valid1, input logic [XLEN-1:0] pc1, input logic [XLEN-1:0] instr1,
    output logic issue0, output logic issue1,
    output logic commit_valid0, output logic [4:0] commit_rd0,
    output logic [XLEN-1:0] commit_data0,
    output logic commit_valid1, output logic [4:0] commit_rd1,
    output logic [XLEN-1:0] commit_data1
);
  decoded_t d0,d1;
  logic [XLEN-1:0] imm0,imm1, a0,b0,a1,b1;
  logic [XLEN-1:0] rs1_data0,rs2_data0,rs1_data1,rs2_data1;
  logic alu_valid0,alu_valid1;

  control_unit dec0(.instr(instr0),.d(d0));
  control_unit dec1(.instr(instr1),.d(d1));
  imm_gen imm_gen0(.instr(instr0),.sel(d0.imm_sel),.imm(imm0));
  imm_gen imm_gen1(.instr(instr1),.sel(d1.imm_sel),.imm(imm1));
  register_file_2wide rf(.clk(clk),
    .rs1_0_addr(d0.rs1_addr),.rs1_0_data(rs1_data0),.rs2_0_addr(d0.rs2_addr),.rs2_0_data(rs2_data0),
    .rs1_1_addr(d1.rs1_addr),.rs1_1_data(rs1_data1),.rs2_1_addr(d1.rs2_addr),.rs2_1_data(rs2_data1),
    .rd0_we(commit_valid0),.rd0_addr(commit_rd0),.rd0_data(commit_data0),
    .rd1_we(commit_valid1),.rd1_addr(commit_rd1),.rd1_data(commit_data1));

  assign alu_valid0=valid0 && !d0.illegal && !d0.mem_read && !d0.mem_write &&
                    !d0.csr && !d0.halt && d0.br_op==BR_NONE;
  assign alu_valid1=valid1 && !d1.illegal && !d1.mem_read && !d1.mem_write &&
                    !d1.csr && !d1.halt && d1.br_op==BR_NONE;
  assign a0=(d0.a_sel==A_PC)?pc0:rs1_data0;
  assign b0=(d0.b_sel==B_IMM)?imm0:rs2_data0;
  assign a1=(d1.a_sel==A_PC)?pc1:rs1_data1;
  assign b1=(d1.b_sel==B_IMM)?imm1:rs2_data1;

  dual_issue_alu #(.ALLOW_LANE1_ALONE(ALLOW_LANE1_ALONE)) exec(
    .clk(clk),.rst_n(rst_n),
    .valid0(alu_valid0),.rs1_0(d0.rs1_addr),.rs1_0_used(d0.a_sel==A_RS1),
    .rs2_0(d0.rs2_addr),.rs2_0_used(d0.b_sel==B_RS2),.rd0(d0.rd_addr),.writes0(d0.rd_we),.a0(a0),.b0(b0),.op0(d0.alu_op),
    .valid1(alu_valid1),.rs1_1(d1.rs1_addr),.rs1_1_used(d1.a_sel==A_RS1),
    .rs2_1(d1.rs2_addr),.rs2_1_used(d1.b_sel==B_RS2),.rd1(d1.rd_addr),.writes1(d1.rd_we),.a1(a1),.b1(b1),.op1(d1.alu_op),
    .issue0(issue0),.issue1(issue1),.commit_valid0(commit_valid0),.commit_rd0(commit_rd0),.commit_data0(commit_data0),
    .commit_valid1(commit_valid1),.commit_rd1(commit_rd1),.commit_data1(commit_data1));
endmodule : dual_issue_decode_execute
