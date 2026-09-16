// Data-carrying coherence channel for write-back MSI caches.
// A snooped cache may return a dirty line directly to the acquiring cache.
interface msi_coherence_if #(
    parameter int unsigned ADDR_W=32,
    parameter int unsigned LINE_W=128
) (input logic clk, input logic rst_n);
  logic acq_valid, acq_ready, acq_write;
  logic [ADDR_W-1:0] acq_addr;
  logic grant_valid, grant_ready;
  logic [1:0] grant_state; // 01=S, 10=M
  logic grant_data_valid;
  logic [LINE_W-1:0] grant_data;
  logic snoop_valid, snoop_ready, snoop_write;
  logic [ADDR_W-1:0] snoop_addr;
  logic snoop_dirty;
  logic [LINE_W-1:0] snoop_data;
  modport cache(
    input clk,rst_n,acq_ready,grant_valid,grant_state,grant_data_valid,grant_data,
          snoop_valid,snoop_addr,snoop_write,
    output acq_valid,acq_write,acq_addr,grant_ready,snoop_ready,snoop_dirty,snoop_data);
  modport hub(
    input clk,rst_n,acq_valid,acq_write,acq_addr,grant_ready,
          snoop_ready,snoop_dirty,snoop_data,
    output acq_ready,grant_valid,grant_state,grant_data_valid,grant_data,
           snoop_valid,snoop_addr,snoop_write);
endinterface : msi_coherence_if
