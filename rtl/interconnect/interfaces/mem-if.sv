// ============================================================================
// mem_if -- synchronous request/response memory interface.
//
// A transfer occurs only when valid and ready are both asserted. Requests and
// responses are held stable while stalled. The initial system permits one
// outstanding request per master, so no transaction ID is required.
// ============================================================================
interface mem_if #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32
) (
    input logic clk,
    input logic rst_n
);

  localparam int unsigned BYTE_LANES = DATA_W / 8;

  // --------------------------------------------------------------------------
  // Request channel: master -> slave
  // --------------------------------------------------------------------------
  logic                  req_valid;
  logic                  req_ready;
  logic [ADDR_W-1:0]     req_addr;
  logic                  req_write;
  logic [DATA_W-1:0]     req_wdata;
  logic [BYTE_LANES-1:0] req_be;

  // --------------------------------------------------------------------------
  // Response channel: slave -> master
  // --------------------------------------------------------------------------
  logic                  rsp_valid;
  logic                  rsp_ready;
  logic [DATA_W-1:0]     rsp_rdata;
  logic                  rsp_error;

  // A master holds a request until req_ready acknowledges it, and holds a
  // response acceptance until rsp_valid presents a response.
  modport master (
      input  clk,
      input  rst_n,
      output req_valid,
      output req_addr,
      output req_write,
      output req_wdata,
      output req_be,
      input  req_ready,
      input  rsp_valid,
      input  rsp_rdata,
      input  rsp_error,
      output rsp_ready
  );

  modport slave (
      input  clk,
      input  rst_n,
      input  req_valid,
      input  req_addr,
      input  req_write,
      input  req_wdata,
      input  req_be,
      output req_ready,
      output rsp_valid,
      output rsp_rdata,
      output rsp_error,
      input  rsp_ready
  );

`ifndef SYNTHESIS
  // Protocol safety: a sender must hold a stalled request or response and
  // all of its payload stable until the receiver accepts it.
  property p_request_stable;
    @(posedge clk) disable iff (!rst_n)
      req_valid && !req_ready |=> req_valid &&
        $stable(req_addr) && $stable(req_write) &&
        $stable(req_wdata) && $stable(req_be);
  endproperty

  property p_response_stable;
    @(posedge clk) disable iff (!rst_n)
      rsp_valid && !rsp_ready |=> rsp_valid &&
        $stable(rsp_rdata) && $stable(rsp_error);
  endproperty

  a_request_stable: assert property (p_request_stable)
    else $error("mem_if request changed while stalled");

  a_response_stable: assert property (p_response_stable)
    else $error("mem_if response changed while stalled");
`endif

endinterface : mem_if
