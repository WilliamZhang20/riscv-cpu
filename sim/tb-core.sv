// ============================================================================
// tb_core -- self-checking testbench for the pipelined core.
//
//   $ verilator --binary --timing --assert --top-module tb_core \
//         ../rtl/rv32i-pkg.sv ../rtl/*.sv tb-core.sv
//
// Plusargs:
//   +PROG=<file.hex>   program image        (default test-basic.hex)
//   +TRACE             print one line per retired instruction
//   +MAXCYC=<n>        timeout               (default 100000)
//
// Memory is a single flat von Neumann array: asynchronous read on both ports,
// byte-enabled synchronous write. No latency, no handshake -- the point here is
// to validate the datapath, not the memory system.
//
// Timescale comes from the --timescale flag so every module shares one.
// ============================================================================
module tb_core;

  import rv32i_pkg::*;

  localparam int MEM_WORDS   = 1024;              // 4 KiB, addresses 0x000-0xFFF
  localparam int ADDR_MSB    = $clog2(MEM_WORDS) + 1;
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0500;
  localparam logic [31:0] MAGIC_PASS  = 32'h600D_C0DE;
  localparam logic [31:0] MAGIC_FAIL  = 32'hBAAD_C0DE;

  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic [31:0] imem_addr, imem_rdata;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic        dmem_we;
  logic [3:0]  dmem_be;
  logic        halted, trap_illegal, retire;
  logic [31:0] retire_pc, retire_instr;

  cpu_core #(.RESET_PC(32'h0000_0000)) dut (
      .clk          (clk),
      .rst_n        (rst_n),
      .imem_addr    (imem_addr),
      .imem_rdata   (imem_rdata),
      .dmem_addr    (dmem_addr),
      .dmem_we      (dmem_we),
      .dmem_be      (dmem_be),
      .dmem_wdata   (dmem_wdata),
      .dmem_rdata   (dmem_rdata),
      .halted       (halted),
      .trap_illegal (trap_illegal),
      .retire       (retire),
      .retire_pc    (retire_pc),
      .retire_instr (retire_instr)
  );

  // --------------------------------------------------------------------------
  // Memory model
  // --------------------------------------------------------------------------
  logic [31:0] mem [MEM_WORDS];

  assign imem_rdata = mem[imem_addr[ADDR_MSB:2]];
  assign dmem_rdata = mem[dmem_addr[ADDR_MSB:2]];

  always_ff @(posedge clk) begin
    if (dmem_we) begin
      for (int b = 0; b < 4; b++) begin
        if (dmem_be[b]) mem[dmem_addr[ADDR_MSB:2]][8*b +: 8] <= dmem_wdata[8*b +: 8];
      end
    end
  end

  // --------------------------------------------------------------------------
  // Bookkeeping
  // --------------------------------------------------------------------------
  int unsigned cycles;
  int unsigned retired;
  bit          do_trace;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      cycles  <= 0;
      retired <= 0;
    end else begin
      cycles <= cycles + 1;
      if (retire) begin
        retired <= retired + 1;
        if (do_trace)
          $display("  [%0t] pc=%08h instr=%08h", $time, retire_pc, retire_instr);
      end
    end
  end

  // Bus checks. The magic memory below is indexed by word and would silently
  // absorb a misaligned or out-of-range access, so they are caught here.
  always_comb begin
    if (rst_n) begin
      if (imem_addr >= MEM_WORDS * 4)
        $fatal(1, "FAIL: instruction fetch out of range: %08h", imem_addr);
      if (imem_addr[1:0] != 2'b00)
        $fatal(1, "FAIL: misaligned instruction fetch: %08h", imem_addr);
    end
  end

  // RV32I requires naturally-aligned data accesses unless the implementation
  // explicitly supports misaligned ones; this core does not.
  always_ff @(posedge clk) begin
    if (rst_n && dut.ex_mem_q.valid &&
        (dut.ex_mem_q.d.mem_write || dut.ex_mem_q.d.mem_read)) begin
      if (dmem_addr >= MEM_WORDS * 4)
        $fatal(1, "FAIL: data access out of range: %08h", dmem_addr);
      case (dut.ex_mem_q.d.mem_op)
        MEM_W:
          if (dmem_addr[1:0] != 2'b00)
            $fatal(1, "FAIL: misaligned word access: %08h", dmem_addr);
        MEM_H, MEM_HU:
          if (dmem_addr[0] != 1'b0)
            $fatal(1, "FAIL: misaligned halfword access: %08h", dmem_addr);
        default: ;        // bytes are always aligned
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // Run
  // --------------------------------------------------------------------------
  string       prog;
  int unsigned maxcyc;
  logic [31:0] result;

  initial begin
    if (!$value$plusargs("PROG=%s", prog))     prog   = "test-basic.hex";
    if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 100000;
    do_trace = $test$plusargs("TRACE");

    rst_n = 1'b0;

    foreach (mem[i]) mem[i] = 32'h0000_0000;
    $readmemh(prog, mem);
    $display("tb_core: loaded %s", prog);

    repeat (4) @(posedge clk);
    rst_n <= 1'b1;

    while (!halted && cycles < maxcyc) @(posedge clk);

    if (!halted)
      $fatal(1, "FAIL: timeout after %0d cycles (pc=%08h)", cycles, retire_pc);

    if (trap_illegal)
      $fatal(1, "FAIL: illegal instruction %08h at pc=%08h",
             retire_instr, retire_pc);

    result = mem[RESULT_ADDR[ADDR_MSB:2]];

    $display("tb_core: halted after %0d cycles, %0d instructions retired",
             cycles, retired);
    $display("tb_core: result word @%08h = %08h", RESULT_ADDR, result);

    if (result === MAGIC_PASS) begin
      $display("tb_core: PASS");
      $finish;
    end else if (result === MAGIC_FAIL) begin
      $fatal(1, "FAIL: program reached its fail path (last pc=%08h)", retire_pc);
    end else begin
      $fatal(1, "FAIL: no result magic written (got %08h)", result);
    end
  end

endmodule : tb_core
