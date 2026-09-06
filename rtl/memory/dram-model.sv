// Deterministic variable-latency DRAM model for simulation and integration.
// One request may be outstanding; responses are held until accepted.
module dram_model #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned MEM_BYTES = 65536,
    parameter int unsigned READ_LATENCY = 8,
    parameter int unsigned WRITE_LATENCY = 4,
    parameter logic [ADDR_W-1:0] BASE_ADDR = '0
) (
    mem_if.slave bus
);
  localparam int unsigned LANES = DATA_W / 8;
  localparam int unsigned WORDS = MEM_BYTES / LANES;
  localparam int unsigned IW = (WORDS <= 1) ? 1 : $clog2(WORDS);
  localparam int unsigned MAX_LAT = (READ_LATENCY > WRITE_LATENCY) ? READ_LATENCY : WRITE_LATENCY;
  localparam int unsigned CW = (MAX_LAT <= 1) ? 1 : $clog2(MAX_LAT + 1);
  logic [DATA_W-1:0] mem [WORDS];
  logic busy_q, rsp_valid_q, rsp_error_q;
  logic [CW-1:0] wait_q;
  logic [DATA_W-1:0] rsp_data_q;
  logic [ADDR_W-1:0] addr_q;
  logic write_q;
  logic [DATA_W-1:0] wdata_q;
  logic [LANES-1:0] be_q;
  wire in_range = (bus.req_addr >= BASE_ADDR) && (bus.req_addr < BASE_ADDR + MEM_BYTES);
  wire aligned = (bus.req_be == {LANES{1'b1}}) ? (bus.req_addr[1:0] == 2'b00) : 1'b1;
  wire resp_in_range = (addr_q >= BASE_ADDR) && (addr_q < BASE_ADDR + MEM_BYTES);
  wire resp_aligned = (be_q == {LANES{1'b1}}) ? (addr_q[1:0] == 2'b00) : 1'b1;
  // Latched transaction validation uses request-time fields; model is intentionally single-issue.
  assign bus.req_ready = !busy_q && !rsp_valid_q;
  assign bus.rsp_valid = rsp_valid_q;
  assign bus.rsp_rdata = rsp_data_q;
  assign bus.rsp_error = rsp_error_q;
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      busy_q <= 1'b0; rsp_valid_q <= 1'b0; wait_q <= '0; rsp_data_q <= '0; rsp_error_q <= 1'b0;
      for (int i = 0; i < WORDS; i++) mem[i] <= '0;
    end else begin
      if (rsp_valid_q && bus.rsp_ready) rsp_valid_q <= 1'b0;
      if (busy_q) begin
        if (wait_q != 0) wait_q <= wait_q - 1'b1;
        else begin
          busy_q <= 1'b0; rsp_valid_q <= 1'b1; rsp_error_q <= !resp_in_range || !resp_aligned;
          rsp_data_q <= '0;
          if (resp_in_range && resp_aligned) begin
            rsp_data_q <= mem[(addr_q - BASE_ADDR) >> 2];
            if (write_q) for (int b = 0; b < LANES; b++) if (be_q[b])
              mem[(addr_q - BASE_ADDR) >> 2][8*b +: 8] <= wdata_q[8*b +: 8];
          end
        end
      end else if (bus.req_valid && bus.req_ready) begin
        busy_q <= 1'b1; addr_q <= bus.req_addr; write_q <= bus.req_write;
        wdata_q <= bus.req_wdata; be_q <= bus.req_be;
        wait_q <= CW'(bus.req_write ? WRITE_LATENCY : READ_LATENCY);
      end
    end
  end
`ifndef SYNTHESIS
  initial for (int i = 0; i < WORDS; i++) mem[i] = '0;
`endif
endmodule
