// Broadcast-invalidation hub for write-through private L1 data caches.
module coherence_hub #(
    parameter int unsigned NUM_CACHES = 2,
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned LINE_BYTES = 16
) (
    input logic clk,
    input logic rst_n,
    coherence_if.hub cache_port [NUM_CACHES]
);
  localparam int unsigned IDX_W = (NUM_CACHES <= 1) ? 1 : $clog2(NUM_CACHES);
  localparam int unsigned OFFSET_W = $clog2(LINE_BYTES);
  typedef enum logic [1:0] {S_IDLE, S_INVALIDATE, S_ACK} state_e;
  state_e state_q;
  logic [IDX_W-1:0] owner_q;
  logic [ADDR_W-1:0] line_addr_q;
  logic [NUM_CACHES-1:0] pending_q;

  logic [NUM_CACHES-1:0] req_valid_v, req_ready_v;
  logic [NUM_CACHES-1:0] ack_valid_v, ack_ready_v;
  logic [NUM_CACHES-1:0] inv_valid_v, inv_ready_v;
  logic [ADDR_W-1:0] req_addr_v [NUM_CACHES];
  logic selected;

  generate
    for (genvar g = 0; g < NUM_CACHES; g++) begin : g_ports
      assign req_valid_v[g] = cache_port[g].req_valid;
      assign req_addr_v[g]  = cache_port[g].req_addr;
      assign ack_ready_v[g] = cache_port[g].ack_ready;
      assign inv_ready_v[g] = cache_port[g].inv_ready;
      assign cache_port[g].req_ready = req_ready_v[g];
      assign cache_port[g].ack_valid = ack_valid_v[g];
      assign cache_port[g].inv_valid = inv_valid_v[g];
      assign cache_port[g].inv_addr  = line_addr_q;
    end
  endgenerate

  always_comb begin
    req_ready_v = '0;
    ack_valid_v = '0;
    inv_valid_v = '0;
    selected = 1'b0;
    if (state_q == S_IDLE) begin
      for (int i = 0; i < NUM_CACHES; i++) begin
        if (req_valid_v[i] && !selected) begin
          req_ready_v[i] = 1'b1;
          selected = 1'b1;
        end
      end
    end else if (state_q == S_INVALIDATE) begin
      inv_valid_v = pending_q;
    end else begin
      ack_valid_v[owner_q] = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= S_IDLE;
      owner_q <= '0;
      line_addr_q <= '0;
      pending_q <= '0;
    end else begin
      unique case (state_q)
        S_IDLE: begin
          for (int i = 0; i < NUM_CACHES; i++) begin
            if (req_valid_v[i] && req_ready_v[i]) begin
              owner_q <= IDX_W'(i);
              line_addr_q <= {req_addr_v[i][ADDR_W-1:OFFSET_W],
                               {OFFSET_W{1'b0}}};
              for (int j = 0; j < NUM_CACHES; j++)
                pending_q[j] <= (j != i);
              state_q <= S_INVALIDATE;
            end
          end
        end
        S_INVALIDATE: begin
          logic any_waiting;
          any_waiting = 1'b0;
          for (int i = 0; i < NUM_CACHES; i++) begin
            if (pending_q[i] && inv_ready_v[i])
              pending_q[i] <= 1'b0;
            if (pending_q[i] && !inv_ready_v[i])
              any_waiting = 1'b1;
          end
          if (!any_waiting) state_q <= S_ACK;
        end
        S_ACK: if (ack_ready_v[owner_q]) state_q <= S_IDLE;
        default: state_q <= S_IDLE;
      endcase
    end
  end
endmodule : coherence_hub
