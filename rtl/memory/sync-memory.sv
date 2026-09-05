// ============================================================================
// sync_memory -- clocked, byte-enabled memory target for mem_if.
//
// One request may be outstanding. An accepted request produces a response on
// a later clock edge, and the response is held until the master accepts it.
// ============================================================================
module sync_memory #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned MEM_BYTES = 4096,
    parameter logic [ADDR_W-1:0] BASE_ADDR = '0
) (
    mem_if.slave bus
);

  localparam int unsigned BYTE_LANES = DATA_W / 8;
  localparam int unsigned WORDS = MEM_BYTES / BYTE_LANES;
  localparam int unsigned INDEX_W = (WORDS <= 1) ? 1 : $clog2(WORDS);

  logic [DATA_W-1:0] mem [WORDS];
  logic              rsp_valid_q;
  logic [DATA_W-1:0] rsp_rdata_q;
  logic              rsp_error_q;

  logic              req_in_range;
  logic              req_aligned;
  logic              req_fire;
  logic              rsp_fire;
  logic [ADDR_W-1:0] word_addr;

  assign bus.req_ready = !rsp_valid_q;
  assign bus.rsp_valid = rsp_valid_q;
  assign bus.rsp_rdata = rsp_rdata_q;
  assign bus.rsp_error = rsp_error_q;

  /* verilator lint_off UNSIGNED */
  assign req_in_range = (bus.req_addr >= BASE_ADDR) &&
                        (bus.req_addr < BASE_ADDR + MEM_BYTES);
  /* verilator lint_on UNSIGNED */

  // Full-word accesses must be word aligned. Byte and halfword alignment is
  // represented by the byte-enable mask and is checked against the address.
  assign req_aligned =
      ((bus.req_be == {BYTE_LANES{1'b1}}) && (bus.req_addr[1:0] == 2'b00)) ||
      ((bus.req_be == 4'b0011) && (bus.req_addr[1:0] == 2'b00)) ||
      ((bus.req_be == 4'b1100) && (bus.req_addr[1:0] == 2'b10)) ||
      ((bus.req_be == 4'b0001) && (bus.req_addr[1:0] == 2'b00)) ||
      ((bus.req_be == 4'b0010) && (bus.req_addr[1:0] == 2'b01)) ||
      ((bus.req_be == 4'b0100) && (bus.req_addr[1:0] == 2'b10)) ||
      ((bus.req_be == 4'b1000) && (bus.req_addr[1:0] == 2'b11));

  assign req_fire = bus.req_valid && bus.req_ready;
  assign rsp_fire = bus.rsp_valid && bus.rsp_ready;
  assign word_addr = (bus.req_addr - BASE_ADDR) >> 2;

  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      rsp_valid_q <= 1'b0;
      rsp_rdata_q <= '0;
      rsp_error_q <= 1'b0;
      for (int i = 0; i < WORDS; i++)
        mem[i] <= '0;
    end else begin
      if (rsp_fire)
        rsp_valid_q <= 1'b0;

      if (req_fire) begin
        rsp_valid_q <= 1'b1;
        rsp_error_q <= !req_in_range || !req_aligned;
        rsp_rdata_q <= '0;

        if (req_in_range && req_aligned) begin
          rsp_rdata_q <= mem[word_addr[INDEX_W-1:0]];
          if (bus.req_write) begin
            for (int b = 0; b < BYTE_LANES; b++) begin
              if (bus.req_be[b])
                mem[word_addr[INDEX_W-1:0]][8*b +: 8] <=
                    bus.req_wdata[8*b +: 8];
            end
          end
        end
      end
    end
  end

`ifndef SYNTHESIS
  initial for (int i = 0; i < WORDS; i++) mem[i] = '0;
`endif

endmodule : sync_memory
