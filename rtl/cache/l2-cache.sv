// Shared blocking L2 built from the verified unified cache controller. L1
// refills appear as ordinary word reads; L1 write-through traffic is propagated
// to memory. Coherence is enforced between private L1Ds, above this level.
module l2_cache #(
    parameter int unsigned ADDR_W      = 32,
    parameter int unsigned DATA_W      = 32,
    parameter int unsigned CACHE_BYTES = 16384,
    parameter int unsigned LINE_BYTES  = 16,
    parameter logic [ADDR_W-1:0] CACHE_BASE  = 32'h0000_0000,
    parameter logic [ADDR_W-1:0] CACHE_LIMIT = 32'h7FFF_FFFF
) (
    mem_if.slave  upstream,
    mem_if.master memory
);
  coherence_if #(.ADDR_W(ADDR_W)) unused_coherence(upstream.clk,
                                                    upstream.rst_n);
  assign unused_coherence.req_ready = 1'b1;
  assign unused_coherence.ack_valid = 1'b1;
  assign unused_coherence.inv_valid = 1'b0;
  assign unused_coherence.inv_addr  = '0;

  l1d_cache #(
      .ADDR_W            (ADDR_W),
      .DATA_W            (DATA_W),
      .CACHE_BYTES       (CACHE_BYTES),
      .LINE_BYTES        (LINE_BYTES),
      .CACHE_BASE        (CACHE_BASE),
      .CACHE_LIMIT       (CACHE_LIMIT),
      .ENABLE_COHERENCE  (1'b0)
  ) u_cache (
      .cpu       (upstream),
      .memory    (memory),
      .coherence (unused_coherence)
  );
endmodule : l2_cache
