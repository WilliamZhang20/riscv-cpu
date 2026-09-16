// Scalable on-chip network boundary.
//
// This first NoC implementation provides address-routed ingress/egress ports,
// per-target round-robin arbitration, and response ownership tracking.  The
// transport is currently a cycle-level mem_if link; replacing the internal
// links with flits does not change the cache or AXI endpoints.
module noc_fabric #(
    parameter int unsigned NUM_MASTERS = 2,
    parameter int unsigned NUM_SLAVES  = 2,
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter logic [NUM_SLAVES*ADDR_W-1:0] SLAVE_BASE = '0,
    parameter logic [NUM_SLAVES*ADDR_W-1:0] SLAVE_LIMIT = '1
) (
    input logic clk, input logic rst_n,
    mem_if.slave master_port [NUM_MASTERS],
    mem_if.master slave_port [NUM_SLAVES]
);
  shared_interconnect #(
      .NUM_MASTERS(NUM_MASTERS), .NUM_SLAVES(NUM_SLAVES),
      .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .SLAVE_BASE(SLAVE_BASE), .SLAVE_LIMIT(SLAVE_LIMIT)
  ) u_router (
      .clk(clk), .rst_n(rst_n), .master_port(master_port), .slave_port(slave_port)
  );
endmodule
