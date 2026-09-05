// ============================================================================
// l1d_cache -- blocking, direct-mapped level-one data cache.
//
// Policy:
//   * read allocate with complete-line refill
//   * write through
//   * no write allocate
//
// Only one CPU transaction and one downstream transaction may be outstanding.
// Store hits update the cached copy only after downstream success, so a failed
// write cannot leave the cache newer than memory.
// ============================================================================
module l1d_cache #(
    parameter int unsigned ADDR_W       = 32,
    parameter int unsigned DATA_W       = 32,
    parameter int unsigned CACHE_BYTES  = 1024,
    parameter int unsigned LINE_BYTES   = 16,
    parameter logic [ADDR_W-1:0] CACHE_BASE  = 32'h0000_0000,
    parameter logic [ADDR_W-1:0] CACHE_LIMIT = 32'h7FFF_FFFF,
    parameter bit ENABLE_COHERENCE = 1'b1
) (
    mem_if.slave  cpu,
    mem_if.master memory,
    coherence_if.cache coherence
);

  localparam int unsigned BYTE_LANES     = DATA_W / 8;
  localparam int unsigned WORD_BYTES     = DATA_W / 8;
  localparam int unsigned WORDS_PER_LINE = LINE_BYTES / WORD_BYTES;
  localparam int unsigned NUM_LINES      = CACHE_BYTES / LINE_BYTES;
  localparam int unsigned OFFSET_W       = $clog2(LINE_BYTES);
  localparam int unsigned WORD_OFF_W     = $clog2(WORDS_PER_LINE);
  localparam int unsigned INDEX_W        = $clog2(NUM_LINES);
  localparam int unsigned TAG_W          = ADDR_W - OFFSET_W - INDEX_W;

  typedef enum logic [3:0] {
    S_IDLE,
    S_LOOKUP,
    S_REFILL_REQ,
    S_REFILL_RSP,
    S_WRITE_REQ,
    S_WRITE_RSP,
    S_COH_REQ,
    S_COH_ACK,
    S_COH_RELEASE,
    S_RESPONSE
  } state_e;

  state_e state_q;

  logic [TAG_W-1:0]  tag_array [NUM_LINES];
  logic              valid_array [NUM_LINES];
  logic [DATA_W-1:0] data_array [NUM_LINES][WORDS_PER_LINE];

  logic [ADDR_W-1:0] request_addr_q;
  logic              request_write_q;
  logic [DATA_W-1:0] request_wdata_q;
  logic [BYTE_LANES-1:0] request_be_q;
  logic [WORD_OFF_W-1:0] refill_word_q;
  logic              write_hit_q;
  logic [DATA_W-1:0] response_data_q;
  logic              response_error_q;

  logic [INDEX_W-1:0] request_index;
  logic [TAG_W-1:0] request_tag;
  logic [WORD_OFF_W-1:0] request_word;
  logic [ADDR_W-1:0] line_base;
  logic hit;
  logic request_aligned;
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

  // Byte enables encode both access width and byte lane. Reject malformed or
  // unnaturally aligned requests locally, including on cache hits.
  always_comb begin
    unique case (cpu.req_be)
      4'b1111: request_aligned = (cpu.req_addr[1:0] == 2'b00);
      4'b0011: request_aligned = (cpu.req_addr[1:0] == 2'b00);
      4'b1100: request_aligned = (cpu.req_addr[1:0] == 2'b10);
      4'b0001: request_aligned = (cpu.req_addr[1:0] == 2'b00);
      4'b0010: request_aligned = (cpu.req_addr[1:0] == 2'b01);
      4'b0100: request_aligned = (cpu.req_addr[1:0] == 2'b10);
      4'b1000: request_aligned = (cpu.req_addr[1:0] == 2'b11);
      default: request_aligned = 1'b0;
    endcase
  end

  assign cpu.req_ready = (state_q == S_IDLE);
  assign cpu.rsp_valid = (state_q == S_RESPONSE);
  assign cpu.rsp_rdata = response_data_q;
  assign cpu.rsp_error = response_error_q;

  assign memory.req_valid = (state_q == S_REFILL_REQ) ||
                            (state_q == S_WRITE_REQ);
  assign memory.req_addr = (state_q == S_REFILL_REQ)
                         ? line_base + ADDR_W'(refill_word_q * WORD_BYTES)
                         : request_addr_q;
  assign memory.req_write = (state_q == S_WRITE_REQ) && request_write_q;
  assign memory.req_wdata = request_wdata_q;
  assign memory.req_be = (state_q == S_REFILL_REQ)
                       ? {BYTE_LANES{1'b1}} : request_be_q;
  assign memory.rsp_ready = (state_q == S_REFILL_RSP) ||
                            (state_q == S_WRITE_RSP);

  assign coherence.req_valid = ENABLE_COHERENCE && (state_q == S_COH_REQ);
  assign coherence.req_addr  = request_addr_q;
  assign coherence.ack_ready = ENABLE_COHERENCE &&
                               (state_q == S_COH_RELEASE);
  assign coherence.inv_ready = ENABLE_COHERENCE &&
                               ((state_q == S_IDLE) ||
                                (state_q == S_RESPONSE) ||
                                (state_q == S_COH_REQ));

  always_ff @(posedge cpu.clk or negedge cpu.rst_n) begin
    if (!cpu.rst_n) begin
      state_q          <= S_IDLE;
      request_addr_q   <= '0;
      request_write_q  <= 1'b0;
      request_wdata_q  <= '0;
      request_be_q     <= '0;
      refill_word_q    <= '0;
      write_hit_q      <= 1'b0;
      response_data_q  <= '0;
      response_error_q <= 1'b0;
      // Payload arrays intentionally have no reset so they can infer SRAMs.
      for (int line = 0; line < NUM_LINES; line++)
        valid_array[line] <= 1'b0;
    end else begin
      if (coherence.inv_valid && coherence.inv_ready &&
          valid_array[coherence.inv_addr[OFFSET_W + INDEX_W - 1:OFFSET_W]] &&
          tag_array[coherence.inv_addr[OFFSET_W + INDEX_W - 1:OFFSET_W]] ==
              coherence.inv_addr[ADDR_W-1:OFFSET_W + INDEX_W])
        valid_array[coherence.inv_addr[OFFSET_W + INDEX_W - 1:OFFSET_W]]
            <= 1'b0;

      unique case (state_q)
        S_IDLE: begin
          if (cpu.req_valid && cpu.req_ready) begin
            request_addr_q  <= cpu.req_addr;
            request_write_q <= cpu.req_write;
            request_wdata_q <= cpu.req_wdata;
            request_be_q    <= cpu.req_be;
            if (!request_aligned) begin
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
            write_hit_q <= 1'b0;
            state_q     <= S_WRITE_REQ;
          end else if (request_write_q) begin
            write_hit_q <= request_cacheable && hit;
            state_q     <= ENABLE_COHERENCE ? S_COH_REQ : S_WRITE_REQ;
          end else if (hit) begin
            response_data_q  <= data_array[request_index][request_word];
            response_error_q <= 1'b0;
            state_q          <= S_RESPONSE;
          end else begin
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
                tag_array[request_index]   <= request_tag;
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

        S_WRITE_REQ: begin
          if (memory.req_valid && memory.req_ready)
            state_q <= S_WRITE_RSP;
        end

        S_WRITE_RSP: begin
          if (memory.rsp_valid && memory.rsp_ready) begin
            response_data_q  <= memory.rsp_rdata;
            response_error_q <= memory.rsp_error;
            if (!memory.rsp_error && request_write_q && write_hit_q) begin
              for (int byte_lane = 0; byte_lane < BYTE_LANES; byte_lane++) begin
                if (request_be_q[byte_lane])
                  data_array[request_index][request_word]
                            [8*byte_lane +: 8] <=
                      request_wdata_q[8*byte_lane +: 8];
              end
            end
            if (request_write_q && request_cacheable && ENABLE_COHERENCE)
              state_q <= S_COH_RELEASE;
            else
              state_q <= S_RESPONSE;
          end
        end

        S_COH_REQ: begin
          if (coherence.req_valid && coherence.req_ready)
            state_q <= S_COH_ACK;
        end

        S_COH_ACK: begin
          if (coherence.ack_valid)
            state_q <= S_WRITE_REQ;
        end

        S_COH_RELEASE: begin
          if (coherence.ack_valid && coherence.ack_ready)
            state_q <= S_RESPONSE;
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
      else $fatal(1, "l1d_cache currently requires DATA_W=32");
    assert (CACHE_BYTES >= LINE_BYTES && CACHE_BYTES % LINE_BYTES == 0)
      else $fatal(1, "l1d_cache capacity must contain whole lines");
    assert (LINE_BYTES >= WORD_BYTES && LINE_BYTES % WORD_BYTES == 0)
      else $fatal(1, "l1d_cache line must contain whole words");
    assert ((NUM_LINES & (NUM_LINES - 1)) == 0)
      else $fatal(1, "l1d_cache NUM_LINES must be a power of two");
    assert ((WORDS_PER_LINE & (WORDS_PER_LINE - 1)) == 0)
      else $fatal(1, "l1d_cache WORDS_PER_LINE must be a power of two");
  end
`endif

endmodule : l1d_cache
