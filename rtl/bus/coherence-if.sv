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
endinterface : coherence_if
