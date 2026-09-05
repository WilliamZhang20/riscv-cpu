// ============================================================================
// Standalone verification for the write-through, no-write-allocate L1D cache.
// ============================================================================
module tb_l1d_cache;

  localparam int unsigned CACHE_BYTES = 64;
  localparam int unsigned LINE_BYTES  = 16;
  localparam int unsigned MEM_WORDS   = 256;
  localparam logic [31:0] ERROR_WRITE_WORD  = 32'h0000_00C8;
  localparam logic [31:0] ERROR_REFILL_WORD = 32'h0000_00E8;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  mem_if cpu_if(clk, rst_n);
  mem_if memory_if(clk, rst_n);
  coherence_if coherence [1](clk, rst_n);

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

  l1d_cache #(
      .CACHE_BYTES (CACHE_BYTES),
      .LINE_BYTES  (LINE_BYTES)
  ) dut (
      .cpu    (cpu_if),
      .memory (memory_if),
      .coherence (coherence[0])
  );

  coherence_hub #(.NUM_CACHES(1)) u_coherence (
      .clk        (clk),
      .rst_n      (rst_n),
      .cache_port (coherence)
  );

  // Variable-latency memory with persistent byte-enabled storage.
  logic [31:0] mem [MEM_WORDS];
  logic        pending_q;
  logic [31:0] pending_addr_q;
  logic        pending_write_q;
  logic [31:0] pending_wdata_q;
  logic [3:0]  pending_be_q;
  logic [1:0]  delay_q;
  logic        rsp_valid_q;
  logic [31:0] rsp_data_q;
  logic        rsp_error_q;
  int unsigned cycle_q;
  int unsigned downstream_reads;
  int unsigned downstream_writes;

  function automatic logic [31:0] initial_word(input int unsigned index);
    return 32'h5A00_0000 ^ index;
  endfunction

  function automatic logic valid_access(
      input logic [31:0] addr,
      input logic [3:0]  be
  );
    unique case (be)
      4'b1111, 4'b0011: valid_access = (addr[1:0] == 2'b00);
      4'b1100:          valid_access = (addr[1:0] == 2'b10);
      4'b0001:          valid_access = (addr[1:0] == 2'b00);
      4'b0010:          valid_access = (addr[1:0] == 2'b01);
      4'b0100:          valid_access = (addr[1:0] == 2'b10);
      4'b1000:          valid_access = (addr[1:0] == 2'b11);
      default:          valid_access = 1'b0;
    endcase
  endfunction

  assign memory_if.req_ready = !pending_q && !rsp_valid_q &&
                               (cycle_q[1:0] != 2'b00);
  assign memory_if.rsp_valid = rsp_valid_q;
  assign memory_if.rsp_rdata = rsp_data_q;
  assign memory_if.rsp_error = rsp_error_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_q          <= 1'b0;
      pending_addr_q     <= '0;
      pending_write_q    <= 1'b0;
      pending_wdata_q    <= '0;
      pending_be_q       <= '0;
      delay_q            <= '0;
      rsp_valid_q        <= 1'b0;
      rsp_data_q         <= '0;
      rsp_error_q        <= 1'b0;
      cycle_q            <= 0;
      downstream_reads   <= 0;
      downstream_writes  <= 0;
      for (int word = 0; word < MEM_WORDS; word++)
        mem[word] <= initial_word(word);
    end else begin
      cycle_q <= cycle_q + 1;

      if (memory_if.rsp_valid && memory_if.rsp_ready)
        rsp_valid_q <= 1'b0;

      if (memory_if.req_valid && memory_if.req_ready) begin
        if (!valid_access(memory_if.req_addr, memory_if.req_be))
          $fatal(1, "malformed downstream access addr=%08h be=%b",
                 memory_if.req_addr, memory_if.req_be);
        pending_q       <= 1'b1;
        pending_addr_q  <= memory_if.req_addr;
        pending_write_q <= memory_if.req_write;
        pending_wdata_q <= memory_if.req_wdata;
        pending_be_q    <= memory_if.req_be;
        delay_q         <= {1'b0, memory_if.req_addr[2]} + 1'b1;
        if (memory_if.req_write)
          downstream_writes <= downstream_writes + 1;
        else
          downstream_reads <= downstream_reads + 1;
      end

      if (pending_q) begin
        if (delay_q != 0) begin
          delay_q <= delay_q - 1'b1;
        end else begin
          pending_q   <= 1'b0;
          rsp_valid_q <= 1'b1;
          rsp_data_q  <= mem[pending_addr_q[9:2]];
          rsp_error_q <= (pending_addr_q == ERROR_REFILL_WORD) ||
                         (pending_write_q &&
                          pending_addr_q == ERROR_WRITE_WORD);
          if (pending_write_q && pending_addr_q != ERROR_REFILL_WORD &&
              pending_addr_q != ERROR_WRITE_WORD) begin
            for (int byte_lane = 0; byte_lane < 4; byte_lane++) begin
              if (pending_be_q[byte_lane])
                mem[pending_addr_q[9:2]][8*byte_lane +: 8] <=
                    pending_wdata_q[8*byte_lane +: 8];
            end
          end
        end
      end
    end
  end

  task automatic issue_request(
      input logic [31:0] addr,
      input logic        write,
      input logic [31:0] wdata,
      input logic [3:0]  be
  );
    @(negedge clk);
    cpu_req_valid = 1'b1;
    cpu_req_addr  = addr;
    cpu_req_write = write;
    cpu_req_wdata = wdata;
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
    logic held_error;

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

  task automatic load_and_check(
      input logic [31:0] addr,
      input logic [3:0]  be,
      input logic [31:0] expected,
      input int unsigned stall_cycles
  );
    issue_request(addr, 1'b0, '0, be);
    expect_response(expected, 1'b0, stall_cycles);
  endtask

  task automatic store_and_check(
      input logic [31:0] addr,
      input logic [31:0] wdata,
      input logic [3:0]  be
  );
    issue_request(addr, 1'b1, wdata, be);
    // Store response data is not architecturally consumed.
    @(negedge clk);
    while (!cpu_if.rsp_valid) @(negedge clk);
    if (cpu_if.rsp_error)
      $fatal(1, "unexpected store error at %08h", addr);
    cpu_rsp_ready = 1'b1;
    @(posedge clk);
    #1;
    cpu_rsp_ready = 1'b0;
  endtask

  task automatic check_counts(
      input int unsigned reads,
      input int unsigned writes,
      input string reason
  );
    if (downstream_reads != reads || downstream_writes != writes)
      $fatal(1, "%s: reads=%0d/%0d writes=%0d/%0d", reason,
             downstream_reads, reads, downstream_writes, writes);
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

    // Cold read allocates a whole line; spatial and subword reads then hit.
    load_and_check(32'h24, 4'b1111, initial_word(9), 0);
    check_counts(4, 0, "cold refill");
    load_and_check(32'h2B, 4'b1000, initial_word(10), 2);
    check_counts(4, 0, "spatial subword hit");

    // A byte store hit writes through and updates the cached copy only after
    // memory acknowledges it.
    store_and_check(32'h25, 32'h0000_AA00, 4'b0010);
    check_counts(4, 1, "write-through hit");
    load_and_check(32'h24, 4'b1111,
                   (initial_word(9) & 32'hFFFF_00FF) | 32'h0000_AA00, 0);
    check_counts(4, 1, "store-hit cache update");

    // Store miss bypasses the arrays; the following load must still refill.
    store_and_check(32'h80, 32'hCAFE_BABE, 4'b1111);
    check_counts(4, 2, "no-write-allocate store");
    load_and_check(32'h80, 4'b1111, 32'hCAFE_BABE, 0);
    check_counts(8, 2, "read after store miss");

    // Malformed access is rejected without downstream traffic.
    issue_request(32'h22, 1'b0, '0, 4'b0011);
    expect_response('0, 1'b1, 0);
    check_counts(8, 2, "local alignment check");

    // A failed write-through must not mutate a resident cached word.
    load_and_check(32'hC8, 4'b1111, initial_word(50), 0);
    check_counts(12, 2, "line resident before failed store");
    issue_request(32'hC8, 1'b1, 32'hDEAD_BEEF, 4'b1111);
    expect_response('0, 1'b1, 2);
    check_counts(12, 3, "failed write-through");
    load_and_check(32'hC8, 4'b1111, initial_word(50), 0);
    check_counts(12, 3, "failed store cache atomicity");

    // The third beat of this line fails. Retrying must issue all three reads
    // again, proving the partial line was not installed.
    issue_request(32'hEC, 1'b0, '0, 4'b1111);
    expect_response('0, 1'b1, 0);
    check_counts(15, 3, "failed refill");
    issue_request(32'hEC, 1'b0, '0, 4'b1111);
    expect_response('0, 1'b1, 0);
    check_counts(18, 3, "failed refill was not installed");

    // Reset invalidates cached data without resetting payload arrays.
    rst_n <= 1'b0;
    repeat (2) @(posedge clk);
    rst_n <= 1'b1;
    load_and_check(32'h24, 4'b1111, initial_word(9), 0);
    check_counts(4, 0, "reset invalidation");

    // MMIO-region reads and writes bypass allocation and preserve byte enables.
    load_and_check(32'h8000_0020, 4'b1111, initial_word(8), 0);
    load_and_check(32'h8000_0020, 4'b1111, initial_word(8), 0);
    check_counts(6, 0, "uncached read bypass");
    store_and_check(32'h8000_0020, 32'h1357_9BDF, 4'b1111);
    load_and_check(32'h8000_0020, 4'b1111, 32'h1357_9BDF, 0);
    check_counts(7, 1, "uncached write bypass");

    $display("tb_l1d_cache: PASS");
    $finish;
  end

endmodule : tb_l1d_cache
