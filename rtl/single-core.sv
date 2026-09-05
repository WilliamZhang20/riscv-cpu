// ============================================================================
// cpu_core -- five-stage pipelined RV32I core.
//
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
  // Pipeline registers
  // --------------------------------------------------------------------------

  // IF -> ID
  typedef struct packed {
    logic            valid;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;
  } if_id_reg_t;

  if_id_reg_t if_id_q, if_id_n;


  // ID -> EX
  typedef struct packed {
    logic            valid;

    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;

    // Register operands
    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;

    // Register indices
    logic [4:0]      rs1_addr;
    logic [4:0]      rs2_addr;
    logic [4:0]      rd_addr;

    // Immediate
    logic [XLEN-1:0] imm;

    // Decoded control
    decoded_t        d;
  } id_ex_reg_t;

  id_ex_reg_t id_ex_q, id_ex_n;


  // EX -> MEM
  typedef struct packed {
    logic            valid;

    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] rs2_data;     // needed for stores

    logic [4:0]      rs2_addr;     // needed for WB -> MEM store forwarding
    logic [4:0]      rd_addr;

    logic            branch_take;
    logic [XLEN-1:0] branch_target;

    // Carry control needed by MEM/WB
    decoded_t        d;
  } ex_mem_reg_t;

  ex_mem_reg_t ex_mem_q, ex_mem_n;


  // MEM -> WB
  typedef struct packed {
    logic            valid;

    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instr;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] load_data;

    logic [4:0]      rd_addr;

    // Carry writeback control
    decoded_t        d;
  } mem_wb_reg_t;

  mem_wb_reg_t mem_wb_q, mem_wb_n;

  // --------------------------------------------------------------------------
  // PC
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] pc, next_pc;
  logic            pc_en;
  logic            ex_redirect;
  logic [XLEN-1:0] ex_target;
  logic            frontend_stop;
  logic            load_use_stall;
  logic            halted_q, trap_illegal_q;

  assign ex_redirect   = id_ex_q.valid && !id_ex_q.d.illegal &&
                         !id_ex_q.d.halt && branch_take;
  assign ex_target     = (id_ex_q.d.br_op == BR_JALR)
                       ? {alu_result[XLEN-1:1], 1'b0} : alu_result;
  assign frontend_stop = halted_q ||
                         (if_id_q.valid && (d.illegal || d.halt)) ||
                         (id_ex_q.valid &&
                          (id_ex_q.d.illegal || id_ex_q.d.halt)) ||
                         (ex_mem_q.valid &&
                          (ex_mem_q.d.illegal || ex_mem_q.d.halt)) ||
                         (mem_wb_q.valid &&
                          (mem_wb_q.d.illegal || mem_wb_q.d.halt));
  assign load_use_stall = id_ex_q.valid && id_ex_q.d.mem_read &&
                          (id_ex_q.rd_addr != '0) && if_id_q.valid &&
                          ((id_ex_q.rd_addr == d.rs1_addr) ||
                           (id_ex_q.rd_addr == d.rs2_addr));
  assign pc_en         = ex_redirect || (!frontend_stop && !load_use_stall);
  assign next_pc       = ex_redirect ? ex_target : (pc + 32'd4);

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
      .instr (if_id_q.instr),
      .d     (d)
  );

  imm_gen u_imm (
      .instr (if_id_q.instr),
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
      .rd_addr  (mem_wb_q.rd_addr),
      .rd_data  (rf_wdata)
  );

  // --------------------------------------------------------------------------
  // EX: ALU + branch condition
  // --------------------------------------------------------------------------
  logic [XLEN-1:0] alu_a, alu_b, alu_result;
  logic [XLEN-1:0] ex_rs1_data, ex_rs2_data;
  logic [XLEN-1:0] ex_mem_fwd_data;
  logic [XLEN-1:0] mem_store_data;
  logic            branch_take;
  logic            wb_fwd_valid;

  assign wb_fwd_valid = mem_wb_q.valid && mem_wb_q.d.rd_we &&
                        !mem_wb_q.d.illegal && !mem_wb_q.d.halt &&
                        !halted_q;

  // EX/MEM can forward every result except a load; load-use dependencies are
  // stalled for one cycle and then use the MEM/WB forwarding path. This is
  // the writeback-to-execute (WX) path.
  assign ex_mem_fwd_data = (ex_mem_q.d.wb_sel == WB_PC4)
                         ? ex_mem_q.pc + 32'd4 : ex_mem_q.alu_result;

  always_comb begin
    ex_rs1_data = id_ex_q.rs1_data;
    if (ex_mem_q.valid && ex_mem_q.d.rd_we && !ex_mem_q.d.mem_read &&
        (ex_mem_q.rd_addr != '0) &&
        (ex_mem_q.rd_addr == id_ex_q.rs1_addr))
      ex_rs1_data = ex_mem_fwd_data;
    else if (wb_fwd_valid &&
             (mem_wb_q.rd_addr != '0) &&
             (mem_wb_q.rd_addr == id_ex_q.rs1_addr))
      ex_rs1_data = rf_wdata;

    ex_rs2_data = id_ex_q.rs2_data;
    if (ex_mem_q.valid && ex_mem_q.d.rd_we && !ex_mem_q.d.mem_read &&
        (ex_mem_q.rd_addr != '0) &&
        (ex_mem_q.rd_addr == id_ex_q.rs2_addr))
      ex_rs2_data = ex_mem_fwd_data;
    else if (wb_fwd_valid &&
             (mem_wb_q.rd_addr != '0) &&
             (mem_wb_q.rd_addr == id_ex_q.rs2_addr))
      ex_rs2_data = rf_wdata;
  end

  // A store's data is carried into MEM, where it may still be dependent on
  // the instruction currently in WB. Forwarding here is the writeback-to-
  // memory (WM) path. It also makes the store-data path independent of where
  // the value was obtained in EX.
  always_comb begin
    mem_store_data = ex_mem_q.rs2_data;
    if (ex_mem_q.valid && ex_mem_q.d.mem_write &&
        wb_fwd_valid &&
        (mem_wb_q.rd_addr != '0) &&
        (mem_wb_q.rd_addr == ex_mem_q.rs2_addr))
      mem_store_data = rf_wdata;
  end

  always_comb begin
    unique case (id_ex_q.d.a_sel)
      A_PC:    alu_a = id_ex_q.pc;
      A_ZERO:  alu_a = '0;
      default: alu_a = ex_rs1_data;
    endcase
  end

  assign alu_b = (id_ex_q.d.b_sel == B_IMM) ? id_ex_q.imm
                                             : ex_rs2_data;

  alu u_alu (
      .op     (id_ex_q.d.alu_op),
      .a      (alu_a),
      .b      (alu_b),
      .result (alu_result)
  );

  branch_unit u_br (
      .op       (id_ex_q.d.br_op),
      .rs1_data (ex_rs1_data),
      .rs2_data (ex_rs2_data),
      .take     (branch_take)
  );

  // --------------------------------------------------------------------------
  // MEM: address, byte enables, store alignment, load formatting
  // --------------------------------------------------------------------------
  logic [1:0] byte_off;
  assign byte_off = ex_mem_q.alu_result[1:0];

  // Full byte address on the bus: the memory ignores the low two bits, but the
  // testbench (and any real slave) needs them to check alignment.
  assign dmem_addr = ex_mem_q.alu_result;
  assign dmem_we   = ex_mem_q.valid && ex_mem_q.d.mem_write &&
                     !ex_mem_q.d.illegal && !halted_q;

  always_comb begin
    unique case (ex_mem_q.d.mem_op)
      MEM_B:   dmem_be = 4'b0001 << byte_off;
      MEM_H:   dmem_be = byte_off[1] ? 4'b1100 : 4'b0011;
      default: dmem_be = 4'b1111;                          // MEM_W
    endcase
  end

  // Replicate the store data into the lane the byte enables select.
  always_comb begin
    unique case (ex_mem_q.d.mem_op)
      MEM_B:   dmem_wdata = {4{mem_store_data[7:0]}};
      MEM_H:   dmem_wdata = {2{mem_store_data[15:0]}};
      default: dmem_wdata = mem_store_data;                // MEM_W
    endcase
  end

  logic [7:0]  load_byte;
  logic [15:0] load_half;
  assign load_byte = dmem_rdata[8*byte_off   +: 8];
  assign load_half = byte_off[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

  logic [XLEN-1:0] load_data;
  always_comb begin
    unique case (ex_mem_q.d.mem_op)
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
    unique case (mem_wb_q.d.wb_sel)
      WB_MEM:  rf_wdata = mem_wb_q.load_data;
      WB_PC4:  rf_wdata = mem_wb_q.pc + 32'd4;
      default: rf_wdata = mem_wb_q.alu_result;             // WB_ALU, WB_CSR
    endcase
  end

  assign rf_we = mem_wb_q.valid && mem_wb_q.d.rd_we &&
                 !mem_wb_q.d.illegal && !mem_wb_q.d.halt && !halted_q;

  // --------------------------------------------------------------------------
  // Pipeline-register inputs
  // --------------------------------------------------------------------------
  always_comb begin
    if_id_n  = '0;
    id_ex_n  = '0;
    ex_mem_n = '0;
    mem_wb_n = '0;

    if (load_use_stall && !ex_redirect) begin
      if_id_n = if_id_q;
    end else if (!frontend_stop && !ex_redirect) begin
      if_id_n.valid = 1'b1;
      if_id_n.pc    = pc;
      if_id_n.instr = imem_rdata;
    end

    if (!ex_redirect && !load_use_stall) begin
      id_ex_n.valid    = if_id_q.valid;
      id_ex_n.pc       = if_id_q.pc;
      id_ex_n.instr    = if_id_q.instr;
      id_ex_n.rs1_data = rs1_data;
      id_ex_n.rs2_data = rs2_data;
      id_ex_n.rs1_addr = d.rs1_addr;
      id_ex_n.rs2_addr = d.rs2_addr;
      id_ex_n.rd_addr  = d.rd_addr;
      id_ex_n.imm      = imm;
      id_ex_n.d        = d;
    end

    ex_mem_n.valid         = id_ex_q.valid;
    ex_mem_n.pc            = id_ex_q.pc;
    ex_mem_n.instr         = id_ex_q.instr;
    ex_mem_n.alu_result    = alu_result;
    ex_mem_n.rs2_data      = ex_rs2_data;
    ex_mem_n.rs2_addr      = id_ex_q.rs2_addr;
    ex_mem_n.rd_addr       = id_ex_q.rd_addr;
    ex_mem_n.branch_take   = branch_take;
    ex_mem_n.branch_target = ex_target;
    ex_mem_n.d             = id_ex_q.d;

    mem_wb_n.valid      = ex_mem_q.valid;
    mem_wb_n.pc         = ex_mem_q.pc;
    mem_wb_n.instr      = ex_mem_q.instr;
    mem_wb_n.alu_result = ex_mem_q.alu_result;
    mem_wb_n.load_data  = load_data;
    mem_wb_n.rd_addr    = ex_mem_q.rd_addr;
    mem_wb_n.d          = ex_mem_q.d;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        if_id_q  <= '0;
        id_ex_q  <= '0;
        ex_mem_q <= '0;
        mem_wb_q <= '0;
        halted_q       <= 1'b0;
        trap_illegal_q <= 1'b0;
    end else begin
        if_id_q  <= if_id_n;
        id_ex_q  <= id_ex_n;
        ex_mem_q <= ex_mem_n;
        mem_wb_q <= mem_wb_n;
        if (mem_wb_q.valid && (mem_wb_q.d.halt || mem_wb_q.d.illegal)) begin
          halted_q       <= 1'b1;
          trap_illegal_q <= mem_wb_q.d.illegal;
        end
    end
  end

  // --------------------------------------------------------------------------
  // Status / trace
  // --------------------------------------------------------------------------
  assign halted       = halted_q;
  assign trap_illegal = trap_illegal_q;
  assign retire       = mem_wb_q.valid && !mem_wb_q.d.halt &&
                        !mem_wb_q.d.illegal && !halted_q;
  assign retire_pc    = mem_wb_q.pc;
  assign retire_instr = mem_wb_q.instr;

endmodule : cpu_core
