// ============================================================================
// l1i_cache -- blocking, direct-mapped level-one instruction cache.
//
// The CPU side accepts one 32-bit instruction read at a time. A hit is returned
// from the local arrays; a miss refills one complete cache line using sequential
// 32-bit transactions on the memory side. Failed refills are never installed.
// ============================================================================
module l1i_cache #(
    parameter int unsigned ADDR_W       = 32,
    parameter int unsigned DATA_W       = 32,
    parameter int unsigned CACHE_BYTES  = 1024,
    parameter int unsigned LINE_BYTES   = 16,
    parameter logic [ADDR_W-1:0] CACHE_BASE  = 32'h0000_0000,
    parameter logic [ADDR_W-1:0] CACHE_LIMIT = 32'h7FFF_FFFF
) (
    mem_if.slave  cpu,
    mem_if.master memory
);

  localparam int unsigned BYTE_LANES     = DATA_W / 8;
  localparam int unsigned WORD_BYTES     = DATA_W / 8;
  localparam int unsigned WORDS_PER_LINE = LINE_BYTES / WORD_BYTES;
  localparam int unsigned NUM_LINES      = CACHE_BYTES / LINE_BYTES;
  localparam int unsigned OFFSET_W       = $clog2(LINE_BYTES);
  localparam int unsigned WORD_OFF_W     = $clog2(WORDS_PER_LINE);
  localparam int unsigned INDEX_W        = $clog2(NUM_LINES);
  localparam int unsigned TAG_W          = ADDR_W - OFFSET_W - INDEX_W;

  typedef enum logic [2:0] {
    S_IDLE,
    S_LOOKUP,
    S_REFILL_REQ,
    S_REFILL_RSP,
    S_BYPASS_REQ,
    S_BYPASS_RSP,
    S_RESPONSE
  } state_e;

  state_e state_q;

  logic [TAG_W-1:0]  tag_array [NUM_LINES];
  logic              valid_array [NUM_LINES];
  logic [DATA_W-1:0] data_array [NUM_LINES][WORDS_PER_LINE];

  logic [ADDR_W-1:0] request_addr_q;
  logic [WORD_OFF_W-1:0] refill_word_q;
  logic [DATA_W-1:0] response_data_q;
  logic              response_error_q;

  logic [INDEX_W-1:0] request_index;
  logic [TAG_W-1:0] request_tag;
  logic [WORD_OFF_W-1:0] request_word;
  logic [ADDR_W-1:0] line_base;
  logic hit;
  logic request_cacheable;

  assign request_index = request_addr_q[OFFSET_W + INDEX_W - 1:OFFSET_W];
  assign request_tag   = request_addr_q[ADDR_W-1:OFFSET_W + INDEX_W];
  assign request_word  = request_addr_q[OFFSET_W-1:$clog2(WORD_BYTES)];
  assign line_base     = {request_addr_q[ADDR_W-1:OFFSET_W],
                          {OFFSET_W{1'b0}}};
  assign hit = valid_array[request_index] &&
               (tag_array[request_index] == request_tag);
  /* verilator lint_off UNSIGNED */
  assign request_cacheable = (request_addr_q >= CACHE_BASE) &&
                             (request_addr_q <= CACHE_LIMIT);
  /* verilator lint_on UNSIGNED */

  assign cpu.req_ready = (state_q == S_IDLE);
  assign cpu.rsp_valid = (state_q == S_RESPONSE);
  assign cpu.rsp_rdata = response_data_q;
  assign cpu.rsp_error = response_error_q;

  assign memory.req_valid = (state_q == S_REFILL_REQ) ||
                            (state_q == S_BYPASS_REQ);
  assign memory.req_addr  = (state_q == S_BYPASS_REQ) ? request_addr_q :
                            line_base +
                            ADDR_W'(refill_word_q * WORD_BYTES);
  assign memory.req_write = 1'b0;
  assign memory.req_wdata = '0;
  assign memory.req_be    = {BYTE_LANES{1'b1}};
  assign memory.rsp_ready = (state_q == S_REFILL_RSP) ||
                            (state_q == S_BYPASS_RSP);

  always_ff @(posedge cpu.clk or negedge cpu.rst_n) begin
    if (!cpu.rst_n) begin
      state_q          <= S_IDLE;
      request_addr_q   <= '0;
      refill_word_q    <= '0;
      response_data_q  <= '0;
      response_error_q <= 1'b0;
      // Tags and data do not require reset: valid bits guard every lookup.
      // Leaving the payload arrays unreset permits SRAM inference.
      for (int line = 0; line < NUM_LINES; line++)
        valid_array[line] <= 1'b0;
    end else begin
      unique case (state_q)
        S_IDLE: begin
          if (cpu.req_valid && cpu.req_ready) begin
            request_addr_q <= cpu.req_addr;
            // Instruction-side writes, partial reads, and unaligned fetches
            // are rejected locally; a hit must not bypass these checks.
            if (cpu.req_write ||
                (cpu.req_be != {BYTE_LANES{1'b1}}) ||
                (cpu.req_addr[$clog2(WORD_BYTES)-1:0] != '0)) begin
              response_data_q  <= '0;
              response_error_q <= 1'b1;
              state_q          <= S_RESPONSE;
            end else begin
              state_q <= S_LOOKUP;
            end
          end
        end

        S_LOOKUP: begin
          if (!request_cacheable) begin
            state_q <= S_BYPASS_REQ;
          end else if (hit) begin
            response_data_q  <= data_array[request_index][request_word];
            response_error_q <= 1'b0;
            state_q          <= S_RESPONSE;
          end else begin
            // Invalidate the victim before refill so an interrupted or failed
            // refill can never expose a partially replaced line.
            valid_array[request_index] <= 1'b0;
            refill_word_q              <= '0;
            state_q                    <= S_REFILL_REQ;
          end
        end

        S_REFILL_REQ: begin
          if (memory.req_valid && memory.req_ready)
            state_q <= S_REFILL_RSP;
        end

        S_REFILL_RSP: begin
          if (memory.rsp_valid && memory.rsp_ready) begin
            if (memory.rsp_error) begin
              response_data_q  <= '0;
              response_error_q <= 1'b1;
              state_q          <= S_RESPONSE;
            end else begin
              data_array[request_index][refill_word_q] <= memory.rsp_rdata;

              if (refill_word_q == request_word)
                response_data_q <= memory.rsp_rdata;

              if (refill_word_q == WORD_OFF_W'(WORDS_PER_LINE - 1)) begin
                tag_array[request_index]    <= request_tag;
                valid_array[request_index] <= 1'b1;
                response_error_q           <= 1'b0;
                state_q                    <= S_RESPONSE;
              end else begin
                refill_word_q <= refill_word_q + 1'b1;
                state_q       <= S_REFILL_REQ;
              end
            end
          end
        end

        S_BYPASS_REQ: begin
          if (memory.req_valid && memory.req_ready)
            state_q <= S_BYPASS_RSP;
        end

        S_BYPASS_RSP: begin
          if (memory.rsp_valid && memory.rsp_ready) begin
            response_data_q  <= memory.rsp_rdata;
            response_error_q <= memory.rsp_error;
            state_q          <= S_RESPONSE;
          end
        end

        S_RESPONSE: begin
          if (cpu.rsp_valid && cpu.rsp_ready)
            state_q <= S_IDLE;
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

`ifndef SYNTHESIS
  initial begin
    assert (DATA_W == 32)
      else $fatal(1, "l1i_cache currently requires DATA_W=32");
    assert (CACHE_BYTES >= LINE_BYTES && CACHE_BYTES % LINE_BYTES == 0)
      else $fatal(1, "l1i_cache capacity must contain whole lines");
    assert (LINE_BYTES >= WORD_BYTES && LINE_BYTES % WORD_BYTES == 0)
      else $fatal(1, "l1i_cache line must contain whole words");
    assert ((NUM_LINES & (NUM_LINES - 1)) == 0)
      else $fatal(1, "l1i_cache NUM_LINES must be a power of two");
    assert ((WORDS_PER_LINE & (WORDS_PER_LINE - 1)) == 0)
      else $fatal(1, "l1i_cache WORDS_PER_LINE must be a power of two");
  end
`endif

endmodule : l1i_cache
