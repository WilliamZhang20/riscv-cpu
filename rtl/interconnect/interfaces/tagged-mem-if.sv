// Tagged request/response memory interface for nonblocking clients.
// Unlike mem_if, responses may return out of order and carry req_id.
interface tagged_mem_if #(parameter int unsigned ADDR_W=32,
                          parameter int unsigned DATA_W=32,
                          parameter int unsigned ID_W=4)
    (input logic clk, input logic rst_n);
  localparam int unsigned BYTE_LANES=DATA_W/8;
  logic req_valid, req_ready;
  logic [ID_W-1:0] req_id;
  logic [ADDR_W-1:0] req_addr;
  logic req_write;
  logic [DATA_W-1:0] req_wdata;
  logic [BYTE_LANES-1:0] req_be;
  logic rsp_valid, rsp_ready;
  logic [ID_W-1:0] rsp_id;
  logic [DATA_W-1:0] rsp_rdata;
  logic rsp_error;
  modport master(input clk,rst_n,req_ready,rsp_valid,rsp_id,rsp_rdata,rsp_error,
                 output req_valid,req_id,req_addr,req_write,req_wdata,req_be,rsp_ready);
  modport slave(input clk,rst_n,req_valid,req_id,req_addr,req_write,req_wdata,req_be,rsp_ready,
                output req_ready,rsp_valid,rsp_id,rsp_rdata,rsp_error);
endinterface : tagged_mem_if
