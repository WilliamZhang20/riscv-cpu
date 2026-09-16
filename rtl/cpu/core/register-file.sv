// ============================================================================
// register_file -- architectural integer registers x0..x31.
//
// Two asynchronous read ports, one synchronous write port.
//   - x0 reads as zero and ignores writes.
//   - Write-before-read bypass: a read whose address matches an in-flight write
//     on this same edge returns rd_data, which removes the need for a WB->ID
//     forwarding path in the hazard unit once this is pipelined.
//
// No reset port: x1..x31 are architecturally undefined at reset in RISC-V, and
// resetting 31 x 32 flops is real area for no benefit.
// ============================================================================
module register_file
  import rv32i_pkg::*;
(
    input  logic                  clk,

    // read port 1
    input  logic [REG_ADDR_W-1:0] rs1_addr,
    output logic [XLEN-1:0]       rs1_data,

    // read port 2
    input  logic [REG_ADDR_W-1:0] rs2_addr,
    output logic [XLEN-1:0]       rs2_data,

    // write port
    input  logic                  rd_we,
    input  logic [REG_ADDR_W-1:0] rd_addr,
    input  logic [XLEN-1:0]       rd_data
);

  logic [XLEN-1:0] regs [NUM_REGS];

  logic write_en;
  assign write_en = rd_we && (rd_addr != '0);

  always_ff @(posedge clk) begin
    if (write_en) regs[rd_addr] <= rd_data;
  end

  always_comb begin
    if (rs1_addr == '0)                          rs1_data = '0;
    else if (write_en && (rd_addr == rs1_addr))  rs1_data = rd_data;
    else                                         rs1_data = regs[rs1_addr];
  end

  always_comb begin
    if (rs2_addr == '0)                          rs2_data = '0;
    else if (write_en && (rd_addr == rs2_addr))  rs2_data = rd_data;
    else                                         rs2_data = regs[rs2_addr];
  end

`ifndef SYNTHESIS
  // Simulation determinism only -- not a reset, no hardware implied.
  initial for (int i = 0; i < NUM_REGS; i++) regs[i] = '0;
`endif

endmodule : register_file
