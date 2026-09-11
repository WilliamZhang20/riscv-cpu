// Routes an uncached mem_if window to GPU AXI-Lite registers.
module mem_gpu_mmio_router #(parameter logic [31:0] GPU_BASE=32'h8000_0000, parameter int unsigned GPU_BYTES=32)
  (mem_if.slave upstream, mem_if.master memory, axi4_lite_if.master gpu_ctrl);
  typedef enum logic [2:0] {IDLE,W_SEND,W_RESP,R_SEND,R_RESP} state_t;
  state_t state_q; logic [31:0] addr_q,wdata_q; logic [3:0] be_q; logic aw_sent_q,w_sent_q,is_gpu;
  assign is_gpu=(upstream.req_addr>=GPU_BASE)&&(upstream.req_addr<GPU_BASE+GPU_BYTES);
  assign memory.req_valid=upstream.req_valid&&!is_gpu; assign memory.req_addr=upstream.req_addr;
  assign memory.req_write=upstream.req_write; assign memory.req_wdata=upstream.req_wdata; assign memory.req_be=upstream.req_be;
  assign memory.rsp_ready=upstream.rsp_ready&&!is_gpu;
  assign upstream.req_ready=is_gpu ? state_q==IDLE : memory.req_ready;
  assign upstream.rsp_valid=(state_q==W_RESP&&gpu_ctrl.bvalid)||(state_q==R_RESP&&gpu_ctrl.rvalid)||(!is_gpu&&memory.rsp_valid);
  assign upstream.rsp_rdata=(state_q==R_RESP)?gpu_ctrl.rdata:memory.rsp_rdata;
  assign upstream.rsp_error=(state_q==W_RESP)?gpu_ctrl.bresp!=0:(state_q==R_RESP)?gpu_ctrl.rresp!=0:memory.rsp_error;
  assign gpu_ctrl.awaddr=addr_q; assign gpu_ctrl.awvalid=state_q==W_SEND&&!aw_sent_q;
  assign gpu_ctrl.wdata=wdata_q; assign gpu_ctrl.wstrb=be_q; assign gpu_ctrl.wvalid=state_q==W_SEND&&!w_sent_q;
  assign gpu_ctrl.bready=state_q==W_RESP&&upstream.rsp_ready;
  assign gpu_ctrl.araddr=addr_q; assign gpu_ctrl.arvalid=state_q==R_SEND; assign gpu_ctrl.rready=state_q==R_RESP&&upstream.rsp_ready;
  always_ff @(posedge upstream.clk or negedge upstream.rst_n) begin
    if(!upstream.rst_n) begin state_q<=IDLE; addr_q<='0; wdata_q<='0; be_q<='0; aw_sent_q<=0; w_sent_q<=0; end
    else unique case(state_q)
      IDLE: if(upstream.req_valid&&upstream.req_ready&&is_gpu) begin
        addr_q<=upstream.req_addr-GPU_BASE; wdata_q<=upstream.req_wdata; be_q<=upstream.req_be;
        aw_sent_q<=0; w_sent_q<=0; state_q<=upstream.req_write?W_SEND:R_SEND;
      end
      W_SEND: begin
        if(gpu_ctrl.awvalid&&gpu_ctrl.awready) aw_sent_q<=1;
        if(gpu_ctrl.wvalid&&gpu_ctrl.wready) w_sent_q<=1;
        if((aw_sent_q||(gpu_ctrl.awvalid&&gpu_ctrl.awready))&&(w_sent_q||(gpu_ctrl.wvalid&&gpu_ctrl.wready))) state_q<=W_RESP;
      end
      W_RESP: if(gpu_ctrl.bvalid&&gpu_ctrl.bready) state_q<=IDLE;
      R_SEND: if(gpu_ctrl.arvalid&&gpu_ctrl.arready) state_q<=R_RESP;
      R_RESP: if(gpu_ctrl.rvalid&&gpu_ctrl.rready) state_q<=IDLE;
      default: state_q<=IDLE;
    endcase
  end
endmodule
