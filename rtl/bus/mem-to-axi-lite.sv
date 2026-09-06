// One-entry mem_if to AXI4-Lite master bridge. Supports one read or write
// in flight and preserves AXI channel backpressure semantics.
module mem_to_axi_lite #(parameter int unsigned ADDR_W=32, parameter int unsigned DATA_W=32)
  (mem_if.slave upstream, axi4_lite_if.master axi);
  localparam int unsigned STRB_W = DATA_W/8;
  typedef enum logic [2:0] {IDLE, WR_SEND, WR_RESP, RD_SEND, RD_RESP} state_t;
  state_t state_q;
  logic [ADDR_W-1:0] addr_q; logic [DATA_W-1:0] data_q; logic [STRB_W-1:0] be_q;
  logic aw_sent_q, w_sent_q;
  logic aw_fire, w_fire;
  assign upstream.req_ready = (state_q == IDLE);
  assign upstream.rsp_valid = (state_q == WR_RESP && axi.bvalid) || (state_q == RD_RESP && axi.rvalid);
  assign upstream.rsp_rdata = (state_q == RD_RESP) ? axi.rdata : '0;
  assign upstream.rsp_error = (state_q == WR_RESP) ? (axi.bresp != 2'b00) : (state_q == RD_RESP && axi.rresp != 2'b00);
  assign axi.awaddr=addr_q; assign axi.awvalid=(state_q==WR_SEND) && !aw_sent_q;
  assign axi.wdata=data_q; assign axi.wstrb=be_q; assign axi.wvalid=(state_q==WR_SEND) && !w_sent_q;
  assign axi.bready=(state_q==WR_RESP) && upstream.rsp_ready;
  assign axi.araddr=addr_q; assign axi.arvalid=(state_q==RD_SEND);
  assign axi.rready=(state_q==RD_RESP) && upstream.rsp_ready;
  assign aw_fire = axi.awvalid && axi.awready;
  assign w_fire = axi.wvalid && axi.wready;
  always_ff @(posedge upstream.clk or negedge upstream.rst_n) begin
    if (!upstream.rst_n) begin
      state_q <= IDLE;
      aw_sent_q <= 1'b0;
      w_sent_q <= 1'b0;
    end
    else case (state_q)
      IDLE: if (upstream.req_valid && upstream.req_ready) begin
        addr_q<=upstream.req_addr; data_q<=upstream.req_wdata; be_q<=upstream.req_be;
        aw_sent_q <= 1'b0;
        w_sent_q <= 1'b0;
        state_q <= upstream.req_write ? WR_SEND : RD_SEND;
      end
      WR_SEND: begin
        if (aw_fire) aw_sent_q <= 1'b1;
        if (w_fire) w_sent_q <= 1'b1;
        if ((aw_sent_q || aw_fire) && (w_sent_q || w_fire)) state_q<=WR_RESP;
      end
      WR_RESP: if (axi.bvalid && axi.bready) begin
        aw_sent_q <= 1'b0;
        w_sent_q <= 1'b0;
        state_q<=IDLE;
      end
      RD_SEND: if (axi.arvalid && axi.arready) state_q<=RD_RESP;
      RD_RESP: if (axi.rvalid && axi.rready) state_q<=IDLE;
      default: state_q<=IDLE;
    endcase
  end
endmodule
