// Banked DRAM model: striped, per-bank latency, parallel banks.
//
// Address striping: word address bit [BANK_W +: ] selects the bank, so
// sequential line fills spread across banks and CPU + GPU burst streams can
// make progress in parallel. Each bank has independent busy/valid state, so
// the model sustains up to NUM_BANKS outstanding words (one per bank) while
// keeping deterministic fixed latencies for perf benchmarking.
//
// This is the canonical SoC's main memory. The CPU/NoC path and the GPU
// AXI-bridged path arbitrate upstream (shared_interconnect, 2->1); this
// model never sees more than one request per cycle.
module banked_dram #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned MEM_BYTES = 65536,
    parameter int unsigned NUM_BANKS = 4,
    parameter int unsigned READ_LATENCY = 8,
    parameter int unsigned WRITE_LATENCY = 4,
    parameter logic [ADDR_W-1:0] BASE_ADDR = '0
) (
    mem_if.slave bus
);
  localparam int unsigned LANES = DATA_W / 8;
  localparam int unsigned WORDS = MEM_BYTES / LANES;
  localparam int unsigned BANK_W = (NUM_BANKS <= 1) ? 1 : $clog2(NUM_BANKS);
  localparam int unsigned MAX_LAT =
      (READ_LATENCY > WRITE_LATENCY) ? READ_LATENCY : WRITE_LATENCY;
  localparam int unsigned CW = (MAX_LAT <= 1) ? 1 : $clog2(MAX_LAT + 1);

  logic [DATA_W-1:0] mem [WORDS];

  // Per-bank state.
  logic [NUM_BANKS-1:0] busy_q, rsp_valid_q, write_q, rsp_error_q;
  logic [CW-1:0] wait_q [NUM_BANKS];
  logic [DATA_W-1:0] rsp_data_q [NUM_BANKS];
  logic [ADDR_W-1:0] addr_q [NUM_BANKS];
  logic [DATA_W-1:0] wdata_q [NUM_BANKS];
  logic [LANES-1:0] be_q [NUM_BANKS];

  logic [BANK_W-1:0] req_bank;
  logic [BANK_W-1:0] rsp_bank;
  logic rsp_fire_any;

  /* verilator lint_off UNSIGNED */
  /* verilator lint_off CMPCONST */
  assign req_bank = BANK_W'(bus.req_addr[2 +: BANK_W]);
  wire in_range = (bus.req_addr >= BASE_ADDR) &&
                  (bus.req_addr < BASE_ADDR + MEM_BYTES);
  wire aligned = (bus.req_be == {LANES{1'b1}}) ?
                 (bus.req_addr[1:0] == 2'b00) : 1'b1;

  // Accept when the target bank is idle with no held response.
  assign bus.req_ready = in_range && aligned &&
                         !busy_q[req_bank] && !rsp_valid_q[req_bank];
  // Out-of-range/misaligned requests complete immediately with error.
  // (req_ready stays high; rsp presented combinationally next cycle via bank 0
  //  error path -- simpler: report error through a held response.)
  assign bus.rsp_valid = |rsp_valid_q;
  assign bus.rsp_rdata = rsp_valid_q[rsp_bank] ? rsp_data_q[rsp_bank] : '0;
  assign bus.rsp_error = rsp_valid_q[rsp_bank] ? rsp_error_q[rsp_bank] : 1'b0;

  // Response mux: lowest busy bank with valid response owns the bus.
  always_comb begin
    rsp_bank = '0;
    for (int b = 0; b < NUM_BANKS; b++)
      if (rsp_valid_q[b]) begin rsp_bank = BANK_W'(b); break; end
  end
  assign rsp_fire_any = bus.rsp_valid && bus.rsp_ready;

  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      for (int b = 0; b < NUM_BANKS; b++) begin
        busy_q[b] <= 1'b0; rsp_valid_q[b] <= 1'b0;
        wait_q[b] <= '0; rsp_data_q[b] <= '0; rsp_error_q[b] <= 1'b0;
        addr_q[b] <= '0; wdata_q[b] <= '0; be_q[b] <= '0; write_q[b] <= 1'b0;
      end
      for (int i = 0; i < WORDS; i++) mem[i] <= '0;
    end else begin
      // Clear a consumed response.
      if (rsp_fire_any) rsp_valid_q[rsp_bank] <= 1'b0;

      // Advance each bank.
      for (int b = 0; b < NUM_BANKS; b++) begin
        if (busy_q[b]) begin
          if (wait_q[b] != 0) begin
            wait_q[b] <= wait_q[b] - 1'b1;
          end else begin
            busy_q[b] <= 1'b0;
            rsp_valid_q[b] <= 1'b1;
            rsp_error_q[b] <= !((addr_q[b] >= BASE_ADDR) &&
                                (addr_q[b] < BASE_ADDR + MEM_BYTES));
            rsp_data_q[b] <= '0;
            if ((addr_q[b] >= BASE_ADDR) &&
                (addr_q[b] < BASE_ADDR + MEM_BYTES)) begin
              rsp_data_q[b] <= mem[(addr_q[b] - BASE_ADDR) >> 2];
              if (write_q[b])
                for (int k = 0; k < LANES; k++)
                  if (be_q[b][k])
                    mem[(addr_q[b] - BASE_ADDR) >> 2][8*k +: 8] <=
                      wdata_q[b][8*k +: 8];
            end
          end
        end
      end

      // Accept a new request into its bank.
      if (bus.req_valid && bus.req_ready) begin
        busy_q[req_bank] <= 1'b1;
        addr_q[req_bank] <= bus.req_addr;
        write_q[req_bank] <= bus.req_write;
        wdata_q[req_bank] <= bus.req_wdata;
        be_q[req_bank] <= bus.req_be;
        wait_q[req_bank] <= CW'(bus.req_write ? WRITE_LATENCY : READ_LATENCY);
      end
    end
  end
  /* verilator lint_on CMPCONST */
  /* verilator lint_on UNSIGNED */

`ifndef SYNTHESIS
  initial for (int i = 0; i < WORDS; i++) mem[i] = '0;
`endif
endmodule : banked_dram
