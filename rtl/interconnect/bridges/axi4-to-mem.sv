// AXI4 slave -> mem_if master bridge (GPU/DMA -> NoC/DRAM path).
//
// Converts burst INCR reads/writes into serialized single-word mem_if
// transactions. Write responses (B) are collapsed to one per burst; read data
// (R) streams beat-by-beat. Only INCR bursts, 32-bit data, aligned transfers
// are supported -- everything else returns SLVERR (bresp/rresp = 2'b10).
//
// This is the counterpart to mem-to-axi-lite: together they give a complete
// AXI story -- AXI4-Lite for MMIO control, full AXI4 for burst data, mem_if
// for the CPU/cache/NoC fabric.
module axi4_to_mem #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32,
    parameter int unsigned ID_W = 4
) (
    axi4_if.slave axi,
    mem_if.master mem
);
  localparam int unsigned STRB_W = DATA_W / 8;
  localparam int unsigned BEAT_BYTES = DATA_W / 8;

  typedef enum logic [2:0] {S_IDLE, S_W_DATA, S_W_RESP, S_R_ADDR, S_R_DATA} state_e;
  state_e state_q;

  logic [ID_W-1:0]   id_q;
  logic [ADDR_W-1:0] addr_q;
  logic [7:0]        len_q;      // beats remaining (0-based ARLEN/AWLEN)
  logic [7:0]        beat_q;
  logic              is_write_q;
  logic [1:0]        err_q;      // sticky burst error
  logic [DATA_W-1:0] rdata_q;
  logic              rvalid_q, rlast_q;
  logic [1:0]        rresp_q;

  // mem_if request registers (held stable across backpressure).
  logic              mem_req_q, mem_is_write_q;
  logic [ADDR_W-1:0] mem_addr_q;
  logic [DATA_W-1:0] mem_wdata_q;
  logic [STRB_W-1:0] mem_be_q;
  logic              mem_pending_q;

  wire aw_fire = axi.awvalid && axi.awready;
  wire w_fire  = axi.wvalid && axi.wready;
  wire b_fire  = axi.bvalid && axi.bready;
  wire ar_fire = axi.arvalid && axi.arready;
  wire r_fire  = axi.rvalid && axi.rready;
  wire mem_req_fire = mem.req_valid && mem.req_ready;
  wire mem_rsp_fire = mem.rsp_valid && mem.rsp_ready;

  // AXI handshake: accept one address at a time; W follows AW.
  assign axi.awready = (state_q == S_IDLE) && !mem_pending_q;
  assign axi.wready  = (state_q == S_W_DATA) && !mem_pending_q;
  assign axi.bvalid  = (state_q == S_W_RESP);
  assign axi.bid     = id_q;
  assign axi.bresp   = err_q;
  assign axi.arready = (state_q == S_IDLE) && !mem_pending_q;
  assign axi.rvalid  = rvalid_q;
  assign axi.rid     = id_q;
  assign axi.rdata   = rdata_q;
  assign axi.rresp   = rresp_q;
  assign axi.rlast   = rlast_q;

  // mem_if side: one outstanding word transaction.
  assign mem.req_valid = mem_req_q;
  assign mem.req_addr  = mem_addr_q;
  assign mem.req_write = mem_is_write_q;
  assign mem.req_wdata = mem_wdata_q;
  assign mem.req_be    = mem_be_q;
  assign mem.rsp_ready = mem_pending_q;

  always_ff @(posedge axi.clk or negedge axi.rst_n) begin
    if (!axi.rst_n) begin
      state_q <= S_IDLE;
      id_q <= '0; addr_q <= '0; len_q <= '0; beat_q <= '0;
      is_write_q <= 1'b0; err_q <= 2'b00;
      rdata_q <= '0; rvalid_q <= 1'b0; rlast_q <= 1'b0; rresp_q <= 2'b00;
      mem_req_q <= 1'b0; mem_is_write_q <= 1'b0;
      mem_addr_q <= '0; mem_wdata_q <= '0; mem_be_q <= '0;
      mem_pending_q <= 1'b0;
    end else begin
      // Complete a consumed R beat.
      if (rvalid_q && r_fire) rvalid_q <= 1'b0;

      // Complete a mem_if response.
      if (mem_rsp_fire) begin
        mem_pending_q <= 1'b0;
        mem_req_q <= 1'b0;
        if (mem.rsp_error) err_q <= 2'b10;
        if (is_write_q) begin
          // Advance write burst.
          if (beat_q == len_q) begin
            state_q <= S_W_RESP;
          end else begin
            beat_q <= beat_q + 1'b1;
            addr_q <= addr_q + ADDR_W'(BEAT_BYTES);
            state_q <= S_W_DATA;
          end
        end else begin
          // Present read beat downstream.
          rdata_q <= mem.rsp_rdata;
          rresp_q <= mem.rsp_error ? 2'b10 : err_q;
          rlast_q <= (beat_q == len_q);
          rvalid_q <= 1'b1;
          if (beat_q == len_q) begin
            state_q <= S_IDLE;
          end else begin
            beat_q <= beat_q + 1'b1;
            addr_q <= addr_q + ADDR_W'(BEAT_BYTES);
            state_q <= S_R_DATA;
          end
        end
      end

      unique case (state_q)
        S_IDLE: begin
          err_q <= 2'b00;
          if (axi.awvalid && axi.awready) begin
            // Only INCR (2'b01) supported; FIXED/WRAP -> SLVERR path.
            if (axi.awburst != 2'b01) err_q <= 2'b10;
            id_q <= axi.awid;
            addr_q <= axi.awaddr;
            len_q <= axi.awlen;
            beat_q <= '0;
            is_write_q <= 1'b1;
            state_q <= S_W_DATA;
          end else if (axi.arvalid && axi.arready) begin
            if (axi.arburst != 2'b01) err_q <= 2'b10;
            id_q <= axi.arid;
            addr_q <= axi.araddr;
            len_q <= axi.arlen;
            beat_q <= '0;
            is_write_q <= 1'b0;
            state_q <= S_R_DATA;
          end
        end
        S_W_DATA: begin
          if (axi.wvalid && axi.wready && !mem_pending_q) begin
            // Latch one W beat into a mem_if write.
            mem_req_q <= 1'b1;
            mem_is_write_q <= 1'b1;
            mem_addr_q <= addr_q;
            mem_wdata_q <= axi.wdata;
            mem_be_q <= axi.wstrb;
            mem_pending_q <= 1'b1;
            if (axi.wlast != (beat_q == len_q)) err_q <= 2'b10;
          end
        end
        S_W_RESP: begin
          if (b_fire) state_q <= S_IDLE;
        end
        S_R_DATA: begin
          // Issue next read word unless one is in flight or R beat held.
          if (!mem_pending_q && !rvalid_q && !mem_rsp_fire) begin
            mem_req_q <= 1'b1;
            mem_is_write_q <= 1'b0;
            mem_addr_q <= addr_q;
            mem_wdata_q <= '0;
            mem_be_q <= {STRB_W{1'b1}};
            mem_pending_q <= 1'b1;
          end
          // Wait for mem response (handled above); R beat streams out.
          if (rvalid_q && r_fire && (beat_q > len_q)) state_q <= S_IDLE;
        end
        default: state_q <= S_IDLE;
      endcase

      // W-last mismatch on final mem response is already sticky via err_q.
      if (mem_req_fire) mem_req_q <= 1'b0;
    end
  end

`ifndef SYNTHESIS
  a_aw_stable: assert property (@(posedge axi.clk) disable iff (!axi.rst_n)
    axi.awvalid && !axi.awready |=> axi.awvalid && $stable(axi.awaddr) && $stable(axi.awlen));
  a_ar_stable: assert property (@(posedge axi.clk) disable iff (!axi.rst_n)
    axi.arvalid && !axi.arready |=> axi.arvalid && $stable(axi.araddr) && $stable(axi.arlen));
`endif
endmodule : axi4_to_mem
