// ============================================================================
// Standalone verification for the blocking direct-mapped L1 instruction cache.
//
// The downstream model deliberately varies request acceptance and response
// latency. Directed checks cover line refill, spatial hits, conflict eviction,
// CPU response backpressure, local protocol errors, failed refill, and reset.
// ============================================================================
module tb_l1i_cache;

  localparam int unsigned CACHE_BYTES = 64;
  localparam int unsigned LINE_BYTES  = 16;
  localparam logic [31:0] ERROR_WORD  = 32'h0000_00C8;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  mem_if cpu_if(clk, rst_n);
  mem_if memory_if(clk, rst_n);

  logic        cpu_req_valid;
  logic [31:0] cpu_req_addr;
  logic        cpu_req_write;
  logic [31:0] cpu_req_wdata;
  logic [3:0]  cpu_req_be;
  logic        cpu_rsp_ready;

  assign cpu_if.req_valid = cpu_req_valid;
  assign cpu_if.req_addr  = cpu_req_addr;
  assign cpu_if.req_write = cpu_req_write;
  assign cpu_if.req_wdata = cpu_req_wdata;
  assign cpu_if.req_be    = cpu_req_be;
  assign cpu_if.rsp_ready = cpu_rsp_ready;

  l1i_cache #(
      .CACHE_BYTES (CACHE_BYTES),
      .LINE_BYTES  (LINE_BYTES)
  ) dut (
      .cpu    (cpu_if),
      .memory (memory_if)
  );

  // --------------------------------------------------------------------------
  // Variable-latency, backpressured downstream memory model
  // --------------------------------------------------------------------------
  logic        pending_q;
  logic [31:0] pending_addr_q;
  logic [1:0]  delay_q;
  logic        memory_rsp_valid_q;
  logic [31:0] memory_rsp_data_q;
  logic        memory_rsp_error_q;
  int unsigned cycle_q;
  int unsigned downstream_reads;

  function automatic logic [31:0] expected_word(input logic [31:0] addr);
    return 32'hA500_0000 ^ (addr >> 2);
  endfunction

  // Refuse one cycle out of every four even when otherwise idle.
  assign memory_if.req_ready = !pending_q && !memory_rsp_valid_q &&
                               (cycle_q[1:0] != 2'b00);
  assign memory_if.rsp_valid = memory_rsp_valid_q;
  assign memory_if.rsp_rdata = memory_rsp_data_q;
  assign memory_if.rsp_error = memory_rsp_error_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_q          <= 1'b0;
      pending_addr_q     <= '0;
      delay_q            <= '0;
      memory_rsp_valid_q <= 1'b0;
      memory_rsp_data_q  <= '0;
      memory_rsp_error_q <= 1'b0;
      cycle_q            <= 0;
      downstream_reads   <= 0;
    end else begin
      cycle_q <= cycle_q + 1;

      if (memory_if.rsp_valid && memory_if.rsp_ready)
        memory_rsp_valid_q <= 1'b0;

      if (memory_if.req_valid && memory_if.req_ready) begin
        if (memory_if.req_write || memory_if.req_be != 4'b1111 ||
            memory_if.req_addr[1:0] != 2'b00)
          $fatal(1, "malformed refill request at %08h", memory_if.req_addr);
        pending_q        <= 1'b1;
        pending_addr_q   <= memory_if.req_addr;
        delay_q          <= {1'b0, memory_if.req_addr[2]} + 1'b1;
        downstream_reads <= downstream_reads + 1;
      end

      if (pending_q) begin
        if (delay_q != 0) begin
          delay_q <= delay_q - 1'b1;
        end else begin
          pending_q          <= 1'b0;
          memory_rsp_valid_q <= 1'b1;
          memory_rsp_data_q  <= expected_word(pending_addr_q);
          memory_rsp_error_q <= (pending_addr_q == ERROR_WORD);
        end
      end
    end
  end

  task automatic issue_request(
      input logic [31:0] addr,
      input logic        write,
      input logic [3:0]  be
  );
    @(negedge clk);
    cpu_req_valid = 1'b1;
    cpu_req_addr  = addr;
    cpu_req_write = write;
    cpu_req_wdata = 32'hDEAD_BEEF;
    cpu_req_be    = be;
    while (!cpu_if.req_ready) @(negedge clk);
    @(posedge clk);
    #1;
    cpu_req_valid = 1'b0;
  endtask

  task automatic expect_response(
      input logic [31:0] expected,
      input logic        expected_error,
      input int unsigned stall_cycles
  );
    logic [31:0] held_data;
    logic        held_error;

    @(negedge clk);
    while (!cpu_if.rsp_valid) @(negedge clk);
    held_data  = cpu_if.rsp_rdata;
    held_error = cpu_if.rsp_error;

    repeat (stall_cycles) begin
      if (!cpu_if.rsp_valid || cpu_if.rsp_rdata !== held_data ||
          cpu_if.rsp_error !== held_error)
        $fatal(1, "CPU response changed while backpressured");
      @(negedge clk);
    end

    if (cpu_if.rsp_error !== expected_error)
      $fatal(1, "response error mismatch: got=%b expected=%b",
             cpu_if.rsp_error, expected_error);
    if (!expected_error && cpu_if.rsp_rdata !== expected)
      $fatal(1, "response data mismatch: got=%08h expected=%08h",
             cpu_if.rsp_rdata, expected);

    cpu_rsp_ready = 1'b1;
    @(posedge clk);
    #1;
    cpu_rsp_ready = 1'b0;
  endtask

  task automatic read_and_check(
      input logic [31:0] addr,
      input int unsigned stall_cycles
  );
    issue_request(addr, 1'b0, 4'b1111);
    expect_response(expected_word(addr), 1'b0, stall_cycles);
  endtask

  task automatic check_read_count(
      input int unsigned expected,
      input string reason
  );
    if (downstream_reads != expected)
      $fatal(1, "%s: downstream reads=%0d expected=%0d",
             reason, downstream_reads, expected);
  endtask

  initial begin
    cpu_req_valid = 1'b0;
    cpu_req_addr  = '0;
    cpu_req_write = 1'b0;
    cpu_req_wdata = '0;
    cpu_req_be    = 4'b1111;
    cpu_rsp_ready = 1'b0;

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;

    // Cold miss fetches the entire 16-byte line.
    read_and_check(32'h0000_0024, 0);
    check_read_count(4, "cold line refill");

    // Other words in that line are hits and generate no memory traffic.
    read_and_check(32'h0000_0020, 0);
    read_and_check(32'h0000_002C, 3);
    check_read_count(4, "spatial hits");

    // With four sets, +64 bytes aliases the same index and evicts the line.
    read_and_check(32'h0000_0064, 0);
    check_read_count(8, "conflict refill");
    read_and_check(32'h0000_0024, 0);
    check_read_count(12, "conflict eviction");

    // Illegal CPU requests fail locally and never touch downstream memory.
    issue_request(32'h0000_0021, 1'b0, 4'b1111);
    expect_response('0, 1'b1, 0);
    issue_request(32'h0000_0020, 1'b1, 4'b1111);
    expect_response('0, 1'b1, 0);
    issue_request(32'h0000_0020, 1'b0, 4'b0011);
    expect_response('0, 1'b1, 0);
    check_read_count(12, "local request validation");

    // The third beat of this refill fails. The partial line must not install,
    // so retrying the request repeats all three downstream transactions.
    issue_request(32'h0000_00CC, 1'b0, 4'b1111);
    expect_response('0, 1'b1, 2);
    check_read_count(15, "failed refill");
    issue_request(32'h0000_00CC, 1'b0, 4'b1111);
    expect_response('0, 1'b1, 0);
    check_read_count(18, "failed refill was not installed");

    // Reset invalidates a previously hot line.
    rst_n <= 1'b0;
    repeat (2) @(posedge clk);
    rst_n <= 1'b1;
    read_and_check(32'h0000_0024, 0);
    check_read_count(4, "reset invalidation");

    // Addresses outside CACHE_LIMIT bypass allocation on every access.
    read_and_check(32'h8000_0020, 0);
    read_and_check(32'h8000_0020, 0);
    check_read_count(6, "uncached instruction bypass");

    $display("tb_l1i_cache: PASS");
    $finish;
  end

endmodule : tb_l1i_cache
