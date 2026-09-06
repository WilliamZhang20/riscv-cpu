// Interrupt redirect test: an external IRQ flushes the in-flight stream and
// starts execution at TRAP_VECTOR, where the handler terminates with EBREAK.
module tb_interrupt;
  logic clk = 1'b0, rst_n = 1'b0, irq = 1'b0;
  always #5 clk = ~clk;
  mem_if imem(clk, rst_n), dmem(clk, rst_n), fabric_if[2](clk, rst_n);
  mem_if memory_if[1](clk, rst_n);
  logic halted, trap_illegal, interrupt_taken, retire;
  logic [31:0] retire_pc, retire_instr;

  cpu_core #(.RESET_PC(32'h0), .TRAP_VECTOR(32'h100)) dut (
      .clk(clk), .rst_n(rst_n), .irq(irq), .imem(imem), .dmem(dmem),
      .halted(halted), .trap_illegal(trap_illegal),
      .interrupt_taken(interrupt_taken), .retire(retire),
      .retire_pc(retire_pc), .retire_instr(retire_instr));
  // Use the normal memory path for both instruction and data ports.
  assign fabric_if[0].req_valid = imem.req_valid;
  assign fabric_if[0].req_addr = imem.req_addr;
  assign fabric_if[0].req_write = imem.req_write;
  assign fabric_if[0].req_wdata = imem.req_wdata;
  assign fabric_if[0].req_be = imem.req_be;
  assign imem.req_ready = fabric_if[0].req_ready;
  assign imem.rsp_valid = fabric_if[0].rsp_valid;
  assign imem.rsp_rdata = fabric_if[0].rsp_rdata;
  assign imem.rsp_error = fabric_if[0].rsp_error;
  assign fabric_if[0].rsp_ready = imem.rsp_ready;
  assign fabric_if[1].req_valid = dmem.req_valid;
  assign fabric_if[1].req_addr = dmem.req_addr;
  assign fabric_if[1].req_write = dmem.req_write;
  assign fabric_if[1].req_wdata = dmem.req_wdata;
  assign fabric_if[1].req_be = dmem.req_be;
  assign dmem.req_ready = fabric_if[1].req_ready;
  assign dmem.rsp_valid = fabric_if[1].rsp_valid;
  assign dmem.rsp_rdata = fabric_if[1].rsp_rdata;
  assign dmem.rsp_error = fabric_if[1].rsp_error;
  assign fabric_if[1].rsp_ready = dmem.rsp_ready;
  shared_interconnect #(.NUM_MASTERS(2), .NUM_SLAVES(1)) fabric
      (.clk(clk), .rst_n(rst_n), .master_port(fabric_if), .slave_port(memory_if));
  sync_memory #(.MEM_BYTES(1024)) memory (.bus(memory_if[0]));

  int unsigned cycles = 0, retired = 0, retired_before = 0; bit saw_irq;
  logic [31:0] last_retire_pc = 32'b0;
  always @(posedge clk) begin
    if (rst_n) begin
      cycles++;
      if (interrupt_taken) begin saw_irq = 1'b1; retired_before = retired; end
      if (retire) retired++;
      if (retire) last_retire_pc = retire_pc;
    end
  end

  initial begin
    repeat (3) @(posedge clk); rst_n <= 1'b1;
    @(negedge clk);
    memory.mem[0]  = 32'h0010_0093; // addi x1,x0,1
    memory.mem[1]  = 32'hffdff06f; // jal x0,-4
    memory.mem[64] = 32'h3420_21f3; // csrrs x3,mcause,x0 // addi x2,x0,42
    memory.mem[65] = 32'h3020_0073; // mret
    repeat (12) @(posedge clk);
    irq <= 1'b1; @(posedge clk); irq <= 1'b0;
    repeat (40) @(posedge clk);
    if (!saw_irq || halted || trap_illegal || retired <= retired_before || (dut.u_rf.regs[3] !== 32'h8000_000b))
      $fatal(1, "interrupt test failed irq=%0b halted=%0b illegal=%0b mcause=%08h", saw_irq, halted, trap_illegal, dut.u_rf.regs[3]);
    if (last_retire_pc === 32'h100)
      $fatal(1, "handler did not resume after mret irq=%0b halted=%0b cycles=%0d last pc=%08h", saw_irq, halted, cycles, last_retire_pc);
    $display("tb_interrupt: PASS (%0d cycles)", cycles);
    $finish;
  end
endmodule
