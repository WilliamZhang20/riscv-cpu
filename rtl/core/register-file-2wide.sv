// Four-read/two-write architectural register file for the two-wide backend.
// Reads are asynchronous with same-cycle write-before-read bypass. If both
// write ports target a register, lane 1 has priority; the scoreboard normally
// prevents that WAW case.
module register_file_2wide
  import rv32i_pkg::*;
#(parameter bit READ_BYPASS = 1'b1)
(
    input logic clk,
    input logic [REG_ADDR_W-1:0] rs1_0_addr, output logic [XLEN-1:0] rs1_0_data,
    input logic [REG_ADDR_W-1:0] rs2_0_addr, output logic [XLEN-1:0] rs2_0_data,
    input logic [REG_ADDR_W-1:0] rs1_1_addr, output logic [XLEN-1:0] rs1_1_data,
    input logic [REG_ADDR_W-1:0] rs2_1_addr, output logic [XLEN-1:0] rs2_1_data,
    input logic rd0_we, input logic [REG_ADDR_W-1:0] rd0_addr, input logic [XLEN-1:0] rd0_data,
    input logic rd1_we, input logic [REG_ADDR_W-1:0] rd1_addr, input logic [XLEN-1:0] rd1_data
);
  logic [XLEN-1:0] regs [NUM_REGS];
  logic w0,w1;
  assign w0=rd0_we && rd0_addr!='0;
  assign w1=rd1_we && rd1_addr!='0;
  always_ff @(posedge clk) begin
    if (w0 && !(w1 && rd1_addr==rd0_addr)) regs[rd0_addr]<=rd0_data;
    if (w1) regs[rd1_addr]<=rd1_data;
  end
  function automatic logic [XLEN-1:0] read_reg(input logic [REG_ADDR_W-1:0] addr);
    if (addr=='0) read_reg='0;
    else if (READ_BYPASS && w1 && rd1_addr==addr) read_reg=rd1_data;
    else if (READ_BYPASS && w0 && rd0_addr==addr) read_reg=rd0_data;
    else read_reg=regs[addr];
  endfunction
  assign rs1_0_data=read_reg(rs1_0_addr); assign rs2_0_data=read_reg(rs2_0_addr);
  assign rs1_1_data=read_reg(rs1_1_addr); assign rs2_1_data=read_reg(rs2_1_addr);
`ifndef SYNTHESIS
  initial for (int i=0;i<NUM_REGS;i++) regs[i]='0;
  a_x0_immutable: assert property (@(posedge clk) regs[0] == '0);
`endif
endmodule : register_file_2wide
