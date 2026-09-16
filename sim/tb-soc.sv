// Canonical SoC testbench: loads PROG hex into banked DRAM, runs all cores,
// checks the 0x500 magic word, and prints per-core IPC + GPU status.
//
// This is the HW-benchmark harness: run with PROG=bench-ilp /
// bench-dcache-stream / bench-gpu-fill (or test-basic) and compare
// cycles/retired/IPC across HW feature changes.
module tb_soc;
  localparam int unsigned NUM_CORES = 2;
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0500;
  localparam logic [31:0] MAGIC_PASS  = 32'h600D_C0DE;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [NUM_CORES-1:0] irq = '0;
  logic [NUM_CORES-1:0] halted, trap_illegal, interrupt_taken;
  logic [NUM_CORES-1:0] retire_valid0, retire_valid1;
  logic [31:0] retire_pc0 [NUM_CORES], retire_pc1 [NUM_CORES];
  logic [31:0] retire_instr0 [NUM_CORES], retire_instr1 [NUM_CORES];
  logic [4:0] retire_rd0 [NUM_CORES], retire_rd1 [NUM_CORES];
  logic [31:0] retire_data0 [NUM_CORES], retire_data1 [NUM_CORES];
  logic [63:0] cycle_count [NUM_CORES], retired_count [NUM_CORES];
  logic gpu_busy, gpu_done, gpu_error;

  soc #(.NUM_CORES(NUM_CORES)) dut (
      .clk(clk), .rst_n(rst_n), .irq(irq),
      .halted(halted), .trap_illegal(trap_illegal),
      .interrupt_taken(interrupt_taken),
      .retire_valid0(retire_valid0), .retire_valid1(retire_valid1),
      .retire_pc0(retire_pc0), .retire_pc1(retire_pc1),
      .retire_instr0(retire_instr0), .retire_instr1(retire_instr1),
      .retire_rd0(retire_rd0), .retire_rd1(retire_rd1),
      .retire_data0(retire_data0), .retire_data1(retire_data1),
      .cycle_count(cycle_count), .retired_count(retired_count),
      .gpu_busy(gpu_busy), .gpu_done(gpu_done), .gpu_error(gpu_error));

  string prog;
  int unsigned cycles = 0, maxcyc;
  longint unsigned retired_total;

  always @(posedge clk) if (rst_n) cycles++;

  initial begin
    if (!$value$plusargs("PROG=%s", prog)) prog = "test-basic.hex";
    if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 500000;
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
    @(negedge clk);
    $readmemh(prog, dut.dram.mem);
    $display("tb_soc: loaded %s into %m.dut.dram.mem", prog);

    while ((halted != {NUM_CORES{1'b1}}) && (cycles < maxcyc)) @(posedge clk);
    if (cycles >= maxcyc) $fatal(1, "tb_soc FAIL: timeout prog=%s", prog);
    if (|trap_illegal) $fatal(1, "tb_soc FAIL: illegal trap=%b", trap_illegal);
    retired_total = 0;
    for (int c = 0; c < NUM_CORES; c++) begin
      retired_total += retired_count[c];
      $display("tb_soc core%0d: halted=%b trap=%b cycles=%0d retired=%0d IPC=%0.3f",
               c, halted[c], trap_illegal[c], cycle_count[c], retired_count[c],
               cycle_count[c] != 0 ?
                 $itor(retired_count[c]) / $itor(cycle_count[c]) : 0.0);
    end
    // Write-back L1s may hold the magic word dirty; accept it in DRAM,
    // any core's L1D line 16 (set for 0x500), or the L2.
    begin : result_check
      automatic bit ok = (dut.dram.mem[RESULT_ADDR[15:2]] === MAGIC_PASS);
      for (int w = 0; w < 2; w++)
        for (int k = 0; k < 4; k++) begin
          if (dut.g_core[0].d0.line_q[16][w][32*k +: 32] === MAGIC_PASS)
            ok = 1'b1;
          if (dut.g_core[1].d0.line_q[16][w][32*k +: 32] === MAGIC_PASS)
            ok = 1'b1;
        end
      for (int w = 0; w < 2; w++)
        for (int k = 0; k < 4; k++)
          if (dut.l2.u_cache.data_array[80][w][k] === MAGIC_PASS)
            ok = 1'b1;
      if (!ok)
        $fatal(1, "tb_soc FAIL: result=%08h (want %08h) pc0=%08h/%08h instr0=%08h/%08h pc1=%08h/%08h",
               dut.dram.mem[RESULT_ADDR[15:2]], MAGIC_PASS,
               retire_pc0[0], retire_pc0[1], retire_instr0[0], retire_instr0[1],
               retire_pc1[0], retire_pc1[1]);
    end

    $display("tb_soc: PASS prog=%s cycles=%0d retired_total=%0d gpu(done=%b err=%b)",
             prog, cycles, retired_total, gpu_done, gpu_error);
    $finish;
  end
endmodule
