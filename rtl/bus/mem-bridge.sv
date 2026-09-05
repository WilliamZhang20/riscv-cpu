// ============================================================================
// mem_bridge -- one-entry request/response protocol bridge.
//
// The bridge does not alter addresses or access semantics. It decouples an
// upstream master from a downstream slave, allowing both sides to apply
// backpressure while permitting only one outstanding transaction.
// ============================================================================
module mem_bridge #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32
) (
    mem_if.slave  upstream,
    mem_if.master downstream
);

  localparam int unsigned BYTE_LANES = DATA_W / 8;

  logic                  busy_q;
  logic                  req_sent_q;
  logic                  rsp_valid_q;
  logic [ADDR_W-1:0]     addr_q;
  logic                  write_q;
  logic [DATA_W-1:0]     wdata_q;
  logic [BYTE_LANES-1:0] be_q;
  logic [DATA_W-1:0]     rdata_q;
  logic                  error_q;

  logic upstream_req_fire;
  logic downstream_req_fire;
  logic downstream_rsp_fire;
  logic upstream_rsp_fire;

  // The bridge accepts a new request only after the previous response has
  // been consumed by the upstream master.
  assign upstream.req_ready = !busy_q;

  assign downstream.req_valid = busy_q && !req_sent_q;
  assign downstream.req_addr  = addr_q;
  assign downstream.req_write = write_q;
  assign downstream.req_wdata = wdata_q;
  assign downstream.req_be    = be_q;

  // Once a downstream response has been captured, hold it until upstream is
  // ready. This is the key response-side backpressure guarantee.
  assign downstream.rsp_ready = busy_q && req_sent_q && !rsp_valid_q;
  assign upstream.rsp_valid   = rsp_valid_q;
  assign upstream.rsp_rdata   = rdata_q;
  assign upstream.rsp_error   = error_q;

  assign upstream_req_fire   = upstream.req_valid && upstream.req_ready;
  assign downstream_req_fire = downstream.req_valid && downstream.req_ready;
  assign downstream_rsp_fire = downstream.rsp_valid && downstream.rsp_ready;
  assign upstream_rsp_fire   = upstream.rsp_valid && upstream.rsp_ready;

  always_ff @(posedge upstream.clk or negedge upstream.rst_n) begin
    if (!upstream.rst_n) begin
      busy_q      <= 1'b0;
      req_sent_q  <= 1'b0;
      rsp_valid_q <= 1'b0;
      addr_q      <= '0;
      write_q     <= 1'b0;
      wdata_q     <= '0;
      be_q        <= '0;
      rdata_q     <= '0;
      error_q     <= 1'b0;
    end else begin
      if (upstream_req_fire) begin
        busy_q     <= 1'b1;
        req_sent_q <= 1'b0;
        addr_q     <= upstream.req_addr;
        write_q    <= upstream.req_write;
        wdata_q    <= upstream.req_wdata;
        be_q       <= upstream.req_be;
      end

      if (downstream_req_fire)
        req_sent_q <= 1'b1;

      if (downstream_rsp_fire) begin
        rsp_valid_q <= 1'b1;
        rdata_q     <= downstream.rsp_rdata;
        error_q     <= downstream.rsp_error;
      end

      if (upstream_rsp_fire) begin
        busy_q      <= 1'b0;
        rsp_valid_q <= 1'b0;
      end
    end
  end

endmodule : mem_bridge
