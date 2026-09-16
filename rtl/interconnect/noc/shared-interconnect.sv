// ============================================================================
// shared_interconnect -- multi-master, multi-slave memory fabric.
//
// Master-side ports are connected to cores, caches, or other requesters.
// Slave-side ports are connected to memory, peripherals, or bridges.
//
// Arbitration, address decoding, response routing, and (later) coherence
// message transport belong in this module. The initial declaration supports
// one outstanding transaction per master; transaction IDs are therefore not
// part of the mem_if protocol.
// ============================================================================
module shared_interconnect #(
    parameter int unsigned NUM_MASTERS = 4,
    parameter int unsigned NUM_SLAVES  = 1,
    parameter int unsigned ADDR_W      = 32,
    parameter int unsigned DATA_W      = 32,
    // Packed arrays keep parameter overrides portable across simulators. The
    // range for slave s occupies bits s*ADDR_W +: ADDR_W.
    parameter logic [NUM_SLAVES*ADDR_W-1:0] SLAVE_BASE = '0,
    parameter logic [NUM_SLAVES*ADDR_W-1:0] SLAVE_LIMIT = '1
) (
    input logic clk,
    input logic rst_n,

    // A master-side port is presented as a slave to the requester.
    mem_if.slave  master_port [NUM_MASTERS],

    // A slave-side port is driven as a master toward the target device.
    mem_if.master slave_port  [NUM_SLAVES]
);

  // One-hot decode result for each master. A request may match no slave
  // (unmapped address) or, if the configured map overlaps, multiple slaves.
  logic [NUM_SLAVES-1:0] master_slave_sel [NUM_MASTERS];
  logic [ADDR_W-1:0]     slave_base_vec [NUM_SLAVES];
  logic [ADDR_W-1:0]     slave_limit_vec [NUM_SLAVES];
  logic                  master_decode_error [NUM_MASTERS];
  logic                  master_decode_overlap [NUM_MASTERS];
  logic                  master_request_valid [NUM_MASTERS];

  logic                  master_req_valid_vec [NUM_MASTERS];
  logic [ADDR_W-1:0]     master_req_addr_vec [NUM_MASTERS];
  logic                  master_req_write_vec [NUM_MASTERS];
  logic [DATA_W-1:0]     master_req_wdata_vec [NUM_MASTERS];
  logic [DATA_W/8-1:0]   master_req_be_vec [NUM_MASTERS];

  localparam int unsigned MASTER_IDX_W =
      (NUM_MASTERS <= 1) ? 1 : $clog2(NUM_MASTERS);

  logic [NUM_MASTERS-1:0] slave_grant [NUM_SLAVES];
  logic                   slave_grant_valid [NUM_SLAVES];
  logic [MASTER_IDX_W-1:0] slave_grant_master [NUM_SLAVES];
  logic [MASTER_IDX_W-1:0] rr_ptr_q [NUM_SLAVES];
  logic                    slave_busy_q [NUM_SLAVES];
  logic [MASTER_IDX_W-1:0] slave_owner_q [NUM_SLAVES];
  logic                    master_busy_q [NUM_MASTERS];
  logic                    master_error_rsp_q [NUM_MASTERS];

  logic                   slave_req_valid [NUM_SLAVES];
  logic [ADDR_W-1:0]      slave_req_addr [NUM_SLAVES];
  logic                   slave_req_write [NUM_SLAVES];
  logic [DATA_W-1:0]      slave_req_wdata [NUM_SLAVES];
  logic [DATA_W/8-1:0]    slave_req_be [NUM_SLAVES];
  logic                   slave_req_ready_vec [NUM_SLAVES];
  logic                   slave_req_fire [NUM_SLAVES];

  logic                   master_rsp_ready_vec [NUM_MASTERS];
  logic                   master_req_fire [NUM_MASTERS];
  logic                   master_rsp_fire [NUM_MASTERS];
  logic                   master_rsp_valid_vec [NUM_MASTERS];
  logic [DATA_W-1:0]      master_rsp_rdata_vec [NUM_MASTERS];
  logic                   master_rsp_error_vec [NUM_MASTERS];
  logic                   slave_rsp_ready_vec [NUM_SLAVES];
  logic                   slave_rsp_valid_vec [NUM_SLAVES];
  logic [DATA_W-1:0]      slave_rsp_rdata_vec [NUM_SLAVES];
  logic                   slave_rsp_error_vec [NUM_SLAVES];
  logic                   slave_rsp_fire [NUM_SLAVES];

  // --------------------------------------------------------------------------
  // Step 1: address decode
  // --------------------------------------------------------------------------
  // The address map is supplied as inclusive [SLAVE_BASE, SLAVE_LIMIT]
  // ranges. Decode is combinational so arbitration can use the result in the
  // same cycle that a request is presented.
  /* verilator lint_off UNSIGNED */
  /* verilator lint_off CMPCONST */
  generate
    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_master_decode
      assign master_req_valid_vec[m] = master_port[m].req_valid;
      assign master_req_addr_vec[m]  = master_port[m].req_addr;
      assign master_req_write_vec[m] = master_port[m].req_write;
      assign master_req_wdata_vec[m] = master_port[m].req_wdata;
      assign master_req_be_vec[m]    = master_port[m].req_be;

      for (genvar s = 0; s < NUM_SLAVES; s++) begin : g_slave_decode
        assign master_slave_sel[m][s] = master_port[m].req_valid &&
                                        (master_port[m].req_addr >=
                                          slave_base_vec[s]) &&
                                        (master_port[m].req_addr <=
                                          slave_limit_vec[s]);
      end

      assign master_decode_error[m] = master_port[m].req_valid &&
                                      !(|master_slave_sel[m]);
      assign master_decode_overlap[m] =
          $countones(master_slave_sel[m]) > 1;
      assign master_request_valid[m] = master_port[m].req_valid &&
                                       (|master_slave_sel[m]) &&
                                       !master_decode_overlap[m];
    end
  endgenerate

  generate
    for (genvar s = 0; s < NUM_SLAVES; s++) begin : g_address_map
      assign slave_base_vec[s] = SLAVE_BASE[s*ADDR_W +: ADDR_W];
      assign slave_limit_vec[s] = SLAVE_LIMIT[s*ADDR_W +: ADDR_W];
    end
  endgenerate

  // --------------------------------------------------------------------------
  // Step 2: round-robin arbitration
  // --------------------------------------------------------------------------
  // Each slave independently chooses one valid master. A request with an
  // unmapped or overlapping address is not eligible for arbitration.
  always_comb begin
    for (int s = 0; s < NUM_SLAVES; s++) begin
      slave_grant[s]        = '0;
      slave_grant_valid[s] = 1'b0;
      slave_grant_master[s] = '0;

      for (int offset = 0; offset < NUM_MASTERS; offset++) begin
        int candidate;
        candidate = int'(rr_ptr_q[s]);
        candidate = candidate + offset;
        if (candidate >= NUM_MASTERS)
          candidate = candidate - NUM_MASTERS;

        if (!slave_grant_valid[s] &&
            !slave_busy_q[s] &&
            master_request_valid[candidate] &&
            !master_busy_q[candidate] &&
            master_slave_sel[candidate][s]) begin
          slave_grant[s][candidate] = 1'b1;
          slave_grant_valid[s]      = 1'b1;
          slave_grant_master[s]     = MASTER_IDX_W'(candidate);
        end
      end
    end
  end

  // Forward the winning request to each slave and apply slave backpressure to
  // the selected master.
  always_comb begin
    for (int s = 0; s < NUM_SLAVES; s++) begin
      slave_req_valid[s] = slave_grant_valid[s];
      slave_req_addr[s]  = '0;
      slave_req_write[s] = 1'b0;
      slave_req_wdata[s] = '0;
      slave_req_be[s]    = '0;

      if (slave_grant_valid[s]) begin
        slave_req_addr[s]  = master_req_addr_vec[slave_grant_master[s]];
        slave_req_write[s] = master_req_write_vec[slave_grant_master[s]];
        slave_req_wdata[s] = master_req_wdata_vec[slave_grant_master[s]];
        slave_req_be[s]    = master_req_be_vec[slave_grant_master[s]];
      end
    end
  end

  generate
    for (genvar s = 0; s < NUM_SLAVES; s++) begin : g_slave_ports
      assign slave_port[s].req_valid = slave_req_valid[s];
      assign slave_port[s].req_addr  = slave_req_addr[s];
      assign slave_port[s].req_write = slave_req_write[s];
      assign slave_port[s].req_wdata = slave_req_wdata[s];
      assign slave_port[s].req_be    = slave_req_be[s];
      assign slave_req_ready_vec[s] = slave_port[s].req_ready;
      assign slave_req_fire[s] = slave_port[s].req_valid &&
                                  slave_port[s].req_ready;
      assign slave_rsp_valid_vec[s] = slave_port[s].rsp_valid;
      assign slave_rsp_rdata_vec[s] = slave_port[s].rsp_rdata;
      assign slave_rsp_error_vec[s] = slave_port[s].rsp_error;
      assign slave_rsp_fire[s] = slave_rsp_valid_vec[s] &&
                                 slave_rsp_ready_vec[s];
    end

    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_master_ports
      assign master_rsp_ready_vec[m] = master_port[m].rsp_ready;
      assign master_req_fire[m] = master_port[m].req_valid &&
                                  master_port[m].req_ready;
      assign master_rsp_fire[m] = master_rsp_valid_vec[m] &&
                                  master_rsp_ready_vec[m];

      always_comb begin
        master_port[m].req_ready = 1'b0;
        if (!master_busy_q[m]) begin
          // Unmapped and overlapping requests complete locally with an error;
          // they do not need a downstream slave grant.
          if (!master_request_valid[m]) begin
            master_port[m].req_ready = 1'b1;
          end else begin
            for (int s = 0; s < NUM_SLAVES; s++) begin
              if (slave_grant[s][m])
                master_port[m].req_ready = slave_req_ready_vec[s];
            end
          end
        end
      end

      assign master_port[m].rsp_valid = master_rsp_valid_vec[m];
      assign master_port[m].rsp_rdata = master_rsp_rdata_vec[m];
      assign master_port[m].rsp_error = master_rsp_error_vec[m];
    end
  endgenerate

  // --------------------------------------------------------------------------
  // Step 4: response ownership and routing
  // --------------------------------------------------------------------------
  // Each slave response is routed to the master recorded when that slave
  // accepted its request. A master is also marked busy so it cannot create a
  // second outstanding transaction whose response would be ambiguous.
  always_comb begin
    for (int m = 0; m < NUM_MASTERS; m++) begin
      master_rsp_valid_vec[m] = master_error_rsp_q[m];
      master_rsp_rdata_vec[m] = '0;
      master_rsp_error_vec[m] = master_error_rsp_q[m];

      for (int s = 0; s < NUM_SLAVES; s++) begin
        if (slave_busy_q[s] && (slave_owner_q[s] == MASTER_IDX_W'(m))) begin
          master_rsp_valid_vec[m] = slave_rsp_valid_vec[s];
          master_rsp_rdata_vec[m] = slave_rsp_rdata_vec[s];
          master_rsp_error_vec[m] = slave_rsp_error_vec[s];
        end
      end
    end

    for (int s = 0; s < NUM_SLAVES; s++) begin
      slave_rsp_ready_vec[s] = 1'b0;
      if (slave_busy_q[s])
        slave_rsp_ready_vec[s] = master_rsp_ready_vec[slave_owner_q[s]];
    end
  end

  generate
    for (genvar s = 0; s < NUM_SLAVES; s++) begin : g_slave_response_ports
      assign slave_port[s].rsp_ready = slave_rsp_ready_vec[s];
    end
  endgenerate

  // Advance fairness state only after the selected request is accepted by
  // the downstream slave.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int s = 0; s < NUM_SLAVES; s++) begin
        rr_ptr_q[s] <= '0;
        slave_busy_q[s] <= 1'b0;
        slave_owner_q[s] <= '0;
      end
      for (int m = 0; m < NUM_MASTERS; m++) begin
        master_busy_q[m]      <= 1'b0;
        master_error_rsp_q[m] <= 1'b0;
      end
    end else begin
      for (int s = 0; s < NUM_SLAVES; s++) begin
        if (slave_req_fire[s]) begin
          if (slave_grant_master[s] == MASTER_IDX_W'(NUM_MASTERS - 1))
            rr_ptr_q[s] <= '0;
          else
            rr_ptr_q[s] <= slave_grant_master[s] + 1'b1;
          slave_busy_q[s]  <= 1'b1;
          slave_owner_q[s] <= slave_grant_master[s];
        end

        if (slave_rsp_fire[s]) begin
          slave_busy_q[s] <= 1'b0;
          master_busy_q[slave_owner_q[s]] <= 1'b0;
        end
      end

      for (int m = 0; m < NUM_MASTERS; m++) begin
        if (master_req_fire[m]) begin
          master_busy_q[m] <= 1'b1;
          if (!master_request_valid[m])
            master_error_rsp_q[m] <= 1'b1;
        end

        if (master_rsp_fire[m]) begin
          master_busy_q[m]      <= 1'b0;
          master_error_rsp_q[m] <= 1'b0;
        end
      end
    end
  end
  /* verilator lint_on CMPCONST */
  /* verilator lint_on UNSIGNED */

  // Coherence snoop/invalidation transport is intentionally outside this
  // ordinary memory transaction interface and will be added with the caches.

endmodule : shared_interconnect
