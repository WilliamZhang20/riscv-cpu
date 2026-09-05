// ============================================================================
// tb_core -- self-checking integration test for the bus-connected RV32I core.
//
// Plusargs:
//   +PROG=<file.hex>   program image (default test-basic.hex)
//   +TRACE             print one line per retired instruction
//   +MAXCYC=<n>        timeout (default 100000)
//
// The core's instruction and data ports share a real mem_if interconnect and a
// clocked memory target. This keeps the default core test aligned with the
// system-level memory path.
// ============================================================================
module tb_core;

  localparam int unsigned MEM_BYTES = 4096;
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0500;
  localparam logic [31:0] MAGIC_PASS  = 32'h600D_C0DE;
  localparam logic [31:0] MAGIC_FAIL  = 32'hBAAD_C0DE;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  mem_if core_imem_if(clk, rst_n);
  mem_if core_dmem_if(clk, rst_n);
  mem_if fabric_if [2](clk, rst_n);
  mem_if l2_if [1](clk, rst_n);
  mem_if memory_if [1](clk, rst_n);
  coherence_if coherence [1](clk, rst_n);

  logic halted;
  logic trap_illegal;
  logic retire;
  logic [31:0] retire_pc;
  logic [31:0] retire_instr;

  cpu_core #(.RESET_PC(32'h0000_0000)) dut (
      .clk          (clk),
      .rst_n        (rst_n),
      .imem        (core_imem_if),
      .dmem        (core_dmem_if),
      .halted       (halted),
      .trap_illegal (trap_illegal),
      .retire       (retire),
      .retire_pc    (retire_pc),
      .retire_instr (retire_instr)
  );

  l1i_cache u_l1i (
      .cpu    (core_imem_if),
      .memory (fabric_if[0])
  );

  l1d_cache u_l1d (
      .cpu    (core_dmem_if),
      .memory (fabric_if[1]),
      .coherence (coherence[0])
  );

  coherence_hub #(.NUM_CACHES(1)) u_coherence (
      .clk        (clk),
      .rst_n      (rst_n),
      .cache_port (coherence)
  );

  shared_interconnect #(
      .NUM_MASTERS (2),
      .NUM_SLAVES  (1)
  ) u_interconnect (
      .clk         (clk),
      .rst_n       (rst_n),
      .master_port (fabric_if),
      .slave_port  (l2_if)
  );

  l2_cache u_l2 (
      .upstream (l2_if[0]),
      .memory   (memory_if[0])
  );

  sync_memory #(
      .MEM_BYTES (MEM_BYTES)
  ) u_memory (
      .bus (memory_if[0])
  );

  string prog;
  int unsigned cycles;
  int unsigned retired;
  int unsigned maxcyc;
  bit do_trace;
  logic [31:0] result;

  always @(posedge clk) begin
    if (rst_n) begin
      cycles++;
      if (retire) begin
        retired++;
        if (do_trace)
          $display("  [%0t] pc=%08h instr=%08h",
                   $time, retire_pc, retire_instr);
      end
    end
  end

  initial begin
    if (!$value$plusargs("PROG=%s", prog)) prog = "test-basic.hex";
    if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 100000;
    do_trace = $test$plusargs("TRACE");

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;

    // sync_memory clears its storage during reset, so load the image after
    // reset has been released.
    @(negedge clk);
    $readmemh(prog, u_memory.mem);
    $display("tb_core: loaded %s", prog);

    while (!halted && cycles < maxcyc)
      @(posedge clk);

    if (!halted)
      $fatal(1, "FAIL: timeout after %0d cycles (pc=%08h)",
             cycles, retire_pc);

    if (trap_illegal)
      $fatal(1, "FAIL: illegal instruction %08h at pc=%08h",
             retire_instr, retire_pc);

    result = u_memory.mem[RESULT_ADDR[11:2]];

    $display("tb_core: halted after %0d cycles, %0d instructions retired",
             cycles, retired);
    $display("tb_core: result word @%08h = %08h", RESULT_ADDR, result);

    if (result === MAGIC_PASS) begin
      $display("tb_core: PASS");
      $finish;
    end else if (result === MAGIC_FAIL) begin
      $fatal(1, "FAIL: program reached its fail path (last pc=%08h)",
             retire_pc);
    end else begin
      $fatal(1, "FAIL: no result magic written (got %08h)", result);
    end
  end

endmodule : tb_core
