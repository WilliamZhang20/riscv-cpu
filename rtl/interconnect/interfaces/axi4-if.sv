// Minimal burst-capable AXI4 interface for high-bandwidth engines.
// AXI4-Lite remains the control/MMIO interface.
interface axi4_if #(parameter int unsigned ADDR_W=32,
                    parameter int unsigned DATA_W=32,
                    parameter int unsigned ID_W=4)
    (input logic clk, input logic rst_n);
  localparam int unsigned STRB_W = DATA_W/8;
  logic [ID_W-1:0] awid; logic [ADDR_W-1:0] awaddr;
  logic [7:0] awlen; logic [2:0] awsize; logic [1:0] awburst;
  logic awvalid, awready;
  logic [DATA_W-1:0] wdata; logic [STRB_W-1:0] wstrb;
  logic wlast, wvalid, wready;
  logic [ID_W-1:0] bid; logic [1:0] bresp; logic bvalid, bready;
  logic [ID_W-1:0] arid; logic [ADDR_W-1:0] araddr;
  logic [7:0] arlen; logic [2:0] arsize; logic [1:0] arburst;
  logic arvalid, arready;
  logic [ID_W-1:0] rid; logic [DATA_W-1:0] rdata;
  logic [1:0] rresp; logic rlast, rvalid, rready;
  modport master(
    input clk,rst_n,awready,wready,bid,bresp,bvalid,arready,rid,rdata,rresp,rlast,rvalid,
    output awid,awaddr,awlen,awsize,awburst,awvalid,wdata,wstrb,wlast,wvalid,bready,
           arid,araddr,arlen,arsize,arburst,arvalid,rready);
  modport slave(
    input clk,rst_n,awid,awaddr,awlen,awsize,awburst,awvalid,wdata,wstrb,wlast,wvalid,bready,
         arid,araddr,arlen,arsize,arburst,arvalid,rready,
    output awready,wready,bid,bresp,bvalid,arready,rid,rdata,rresp,rlast,rvalid);
endinterface : axi4_if
