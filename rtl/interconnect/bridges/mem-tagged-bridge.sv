// Bridges the legacy one-outstanding core port to a tagged cache port.
// The fixed ID is intentional: the core itself still has one data operation.
module mem_to_tagged #(
    parameter int unsigned ADDR_W=32, parameter int unsigned DATA_W=32,
    parameter int unsigned ID_W=4
) (mem_if.slave upstream, tagged_mem_if.master downstream);
  logic busy_q; logic [ADDR_W-1:0] addr_q; logic wr_q;
  logic [DATA_W-1:0] data_q; logic [DATA_W/8-1:0] be_q;
  assign upstream.req_ready=!busy_q;
  assign downstream.req_valid=busy_q && !downstream.rsp_valid;
  assign downstream.req_id='0; assign downstream.req_addr=addr_q;
  assign downstream.req_write=wr_q; assign downstream.req_wdata=data_q; assign downstream.req_be=be_q;
  assign downstream.rsp_ready=busy_q && upstream.rsp_ready;
  assign upstream.rsp_valid=busy_q && downstream.rsp_valid;
  assign upstream.rsp_rdata=downstream.rsp_rdata; assign upstream.rsp_error=downstream.rsp_error;
  always_ff @(posedge upstream.clk or negedge upstream.rst_n) begin
    if(!upstream.rst_n) busy_q<=0;
    else begin
      if(upstream.req_valid&&upstream.req_ready) begin
        busy_q<=1; addr_q<=upstream.req_addr; wr_q<=upstream.req_write;
        data_q<=upstream.req_wdata; be_q<=upstream.req_be;
      end
      if(upstream.rsp_valid&&upstream.rsp_ready) busy_q<=0;
    end
  end
endmodule : mem_to_tagged

// Serializes a tagged cache's downstream traffic onto the legacy fabric and
// restores the response tag.
module tagged_to_mem #(
    parameter int unsigned ADDR_W=32, parameter int unsigned DATA_W=32,
    parameter int unsigned ID_W=4
) (tagged_mem_if.slave upstream, mem_if.master downstream);
  logic busy_q; logic [ID_W-1:0] id_q;
  assign upstream.req_ready=!busy_q;
  assign downstream.req_valid=upstream.req_valid && upstream.req_ready;
  assign downstream.req_addr=upstream.req_addr; assign downstream.req_write=upstream.req_write;
  assign downstream.req_wdata=upstream.req_wdata; assign downstream.req_be=upstream.req_be;
  assign downstream.rsp_ready=busy_q && upstream.rsp_ready;
  assign upstream.rsp_valid=busy_q && downstream.rsp_valid;
  assign upstream.rsp_id=id_q; assign upstream.rsp_rdata=downstream.rsp_rdata;
  assign upstream.rsp_error=downstream.rsp_error;
  always_ff @(posedge upstream.clk or negedge upstream.rst_n) begin
    if(!upstream.rst_n) begin busy_q<=0; id_q<='0; end
    else begin
      if(upstream.req_valid&&upstream.req_ready) begin busy_q<=1; id_q<=upstream.req_id; end
      if(upstream.rsp_valid&&upstream.rsp_ready) busy_q<=0;
    end
  end
endmodule : tagged_to_mem
