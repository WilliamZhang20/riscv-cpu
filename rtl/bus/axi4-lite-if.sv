// Minimal AXI4-Lite channel interface (32-bit address/data, no bursts/IDs).
interface axi4_lite_if #(parameter int unsigned ADDR_W = 32,
                         parameter int unsigned DATA_W = 32)
    (input logic clk, input logic rst_n);
  localparam int unsigned STRB_W = DATA_W / 8;
  logic [ADDR_W-1:0] awaddr; logic awvalid, awready;
  logic [DATA_W-1:0] wdata; logic [STRB_W-1:0] wstrb; logic wvalid, wready;
  logic [1:0] bresp; logic bvalid, bready;
  logic [ADDR_W-1:0] araddr; logic arvalid, arready;
  logic [DATA_W-1:0] rdata; logic [1:0] rresp; logic rvalid, rready;
  modport master(input clk,rst_n, output awaddr,awvalid,wdata,wstrb,wvalid,bready,araddr,arvalid,rready,
                 input awready,wready,bresp,bvalid,arready,rdata,rresp,rvalid);
  modport slave(input clk,rst_n, input awaddr,awvalid,wdata,wstrb,wvalid,bready,araddr,arvalid,rready,
                output awready,wready,bresp,bvalid,arready,rdata,rresp,rvalid);
endinterface
