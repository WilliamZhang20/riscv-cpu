// Serialized MSI directory/hub for a small private-L1 cluster.
// The hub does not write memory itself: a dirty owner transfers the line to
// the requester, which is the correct cache-to-cache path for shared data.
module msi_coherence_hub #(
    parameter int unsigned NUM_CACHES=2,
    parameter int unsigned ADDR_W=32,
    parameter int unsigned LINE_BYTES=16
) (
    input logic clk, input logic rst_n,
    msi_coherence_if.hub cache_port[NUM_CACHES]
);
  localparam int unsigned LINE_W=LINE_BYTES*8;
  localparam int unsigned IDX_W=(NUM_CACHES<=1)?1:$clog2(NUM_CACHES);
  localparam int unsigned OFF_W=$clog2(LINE_BYTES);
  typedef enum logic [1:0] {IDLE,SNOOP,GRANT} state_t;
  state_t state_q;
  logic [IDX_W-1:0] owner_q;
  logic [ADDR_W-1:0] addr_q;
  logic write_q, dirty_q;
  logic [LINE_W-1:0] data_q;
  logic [NUM_CACHES-1:0] pending_q;
  logic [NUM_CACHES-1:0] acq_valid_v, acq_ready_v, snoop_ready_v;
  logic [NUM_CACHES-1:0] grant_ready_v;
  logic [ADDR_W-1:0] acq_addr_v[NUM_CACHES];
  logic acq_write_v[NUM_CACHES];
  logic [LINE_W-1:0] snoop_data_v[NUM_CACHES];
  logic snoop_dirty_v[NUM_CACHES];

  generate for (genvar i=0;i<NUM_CACHES;i++) begin : g
    assign acq_valid_v[i]=cache_port[i].acq_valid;
    assign acq_addr_v[i]=cache_port[i].acq_addr;
    assign acq_write_v[i]=cache_port[i].acq_write;
    assign snoop_ready_v[i]=cache_port[i].snoop_ready;
    assign grant_ready_v[i]=cache_port[i].grant_ready;
    assign snoop_dirty_v[i]=cache_port[i].snoop_dirty;
    assign snoop_data_v[i]=cache_port[i].snoop_data;
    assign cache_port[i].acq_ready=acq_ready_v[i];
    assign cache_port[i].grant_valid=(state_q==GRANT && owner_q==i);
    assign cache_port[i].grant_state=write_q ? 2'b10 : 2'b01;
    assign cache_port[i].grant_data_valid=(state_q==GRANT && owner_q==i && dirty_q);
    assign cache_port[i].grant_data=data_q;
    assign cache_port[i].snoop_valid=(state_q==SNOOP && pending_q[i]);
    assign cache_port[i].snoop_addr=addr_q;
    assign cache_port[i].snoop_write=write_q;
  end endgenerate

  always_comb begin
    acq_ready_v='0;
    if (state_q==IDLE) begin
      for (int i=0;i<NUM_CACHES;i++)
        if (acq_valid_v[i] && !(|acq_ready_v)) acq_ready_v[i]=1'b1;
    end
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q<=IDLE; owner_q<='0; addr_q<='0; write_q<=1'b0;
      dirty_q<=1'b0; data_q<='0; pending_q<='0;
    end else begin
      unique case (state_q)
        IDLE: for (int i=0;i<NUM_CACHES;i++) begin
          if (acq_valid_v[i] && acq_ready_v[i]) begin
            owner_q<=IDX_W'(i); addr_q<={acq_addr_v[i][ADDR_W-1:OFF_W],{OFF_W{1'b0}}};
            write_q<=acq_write_v[i]; pending_q<='0;
            for (int j=0;j<NUM_CACHES;j++) pending_q[j]<=(j!=i);
            dirty_q<=1'b0; state_q<=SNOOP;
          end
        end
        SNOOP: begin
          for (int i=0;i<NUM_CACHES;i++) if (pending_q[i] && snoop_ready_v[i]) begin
            pending_q[i]<=1'b0;
            if (snoop_dirty_v[i]) begin dirty_q<=1'b1; data_q<=snoop_data_v[i]; end
          end
          if (!(|pending_q)) state_q<=GRANT;
        end
        GRANT: if (grant_ready_v[owner_q]) state_q<=IDLE;
        default: state_q<=IDLE;
      endcase
    end
  end
`ifndef SYNTHESIS
  a_no_grant_with_pending_snoop: assert property (@(posedge clk) disable iff (!rst_n) state_q == GRANT |-> !(|pending_q));
`endif
endmodule : msi_coherence_hub
