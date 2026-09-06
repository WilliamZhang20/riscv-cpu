interface coherence_if #(parameter int unsigned ADDR_W = 32) (
    input logic clk,
    input logic rst_n
);
  logic req_valid, req_ready;
  logic [ADDR_W-1:0] req_addr;
  logic ack_valid, ack_ready;
  logic inv_valid, inv_ready;
  logic [ADDR_W-1:0] inv_addr;

  modport cache (
      input clk, rst_n, req_ready, ack_valid, inv_valid, inv_addr,
      output req_valid, req_addr, ack_ready, inv_ready
  );
  modport hub (
      input clk, rst_n, req_valid, req_addr, ack_ready, inv_ready,
      output req_ready, ack_valid, inv_valid, inv_addr
  );
`ifndef SYNTHESIS
  property p_req_stable; @(posedge clk) disable iff (!rst_n) req_valid && !req_ready |=> req_valid && $stable(req_addr); endproperty
  property p_inv_stable; @(posedge clk) disable iff (!rst_n) inv_valid && !inv_ready |=> inv_valid && $stable(inv_addr); endproperty
  a_req_stable: assert property (p_req_stable) else $error("coherence request changed while stalled");
  a_inv_stable: assert property (p_inv_stable) else $error("coherence invalidation changed while stalled");
`endif
endinterface : coherence_if
