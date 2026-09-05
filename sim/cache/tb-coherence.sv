module tb_coherence;
  localparam int N = 2;
  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;
  mem_if cpu_if[N](clk, rst_n);
  mem_if fabric_if[N](clk, rst_n);
  mem_if memory_if[1](clk, rst_n);
  coherence_if coherence[N](clk, rst_n);

  logic valid[N], write[N], ready[N];
  logic [31:0] addr[N], wdata[N], rdata[N];
  logic [3:0] be[N];
  logic rsp_valid[N], rsp_error[N];

  generate for (genvar g=0; g<N; g++) begin : g_cache
    assign cpu_if[g].req_valid=valid[g]; assign cpu_if[g].req_addr=addr[g];
    assign cpu_if[g].req_write=write[g]; assign cpu_if[g].req_wdata=wdata[g];
    assign cpu_if[g].req_be=be[g]; assign cpu_if[g].rsp_ready=1'b1;
    assign ready[g]=cpu_if[g].req_ready; assign rsp_valid[g]=cpu_if[g].rsp_valid;
    assign rdata[g]=cpu_if[g].rsp_rdata; assign rsp_error[g]=cpu_if[g].rsp_error;
    l1d_cache #(.CACHE_BYTES(64)) cache (
      .cpu(cpu_if[g]), .memory(fabric_if[g]), .coherence(coherence[g]));
  end endgenerate

  coherence_hub #(.NUM_CACHES(N)) hub
    (.clk(clk), .rst_n(rst_n), .cache_port(coherence));
  shared_interconnect #(.NUM_MASTERS(N),.NUM_SLAVES(1)) fabric
    (.clk(clk),.rst_n(rst_n),.master_port(fabric_if),.slave_port(memory_if));
  sync_memory #(.MEM_BYTES(4096)) memory (.bus(memory_if[0]));

  int transactions;
  always @(posedge clk) if (rst_n && memory_if[0].req_valid &&
                            memory_if[0].req_ready) transactions++;

  task automatic access(input int m, input bit wr, input logic [31:0] a,
                        input logic [31:0] wd, input logic [31:0] expected);
    @(negedge clk); valid[m]=1; write[m]=wr; addr[m]=a; wdata[m]=wd; be[m]=4'hf;
    while (!ready[m]) @(negedge clk);
    @(posedge clk); #1 valid[m]=0;
    @(negedge clk); while (!rsp_valid[m]) @(negedge clk);
    if (rsp_error[m] || (!wr && rdata[m] !== expected))
      $fatal(1,"cache %0d access failed got=%08h expected=%08h",m,rdata[m],expected);
    @(posedge clk);
  endtask

  initial begin
    for (int i=0;i<N;i++) begin valid[i]=0; write[i]=0; addr[i]=0;
      wdata[i]=0; be[i]=4'hf; end
    repeat(3) @(posedge clk); rst_n<=1;
    @(negedge clk); memory.mem[32'h100>>2]=32'h1111_1111;

    access(0,0,32'h100,0,32'h1111_1111);
    access(1,0,32'h100,0,32'h1111_1111);
    if (transactions != 8) $fatal(1,"both private fills not observed");
    access(0,1,32'h100,32'h2222_2222,0);
    access(1,0,32'h100,0,32'h2222_2222);
    if (transactions != 13) $fatal(1,"cache 1 was not invalidated");
    access(1,1,32'h100,32'h3333_3333,0);
    access(0,0,32'h100,0,32'h3333_3333);
    if (transactions != 18) $fatal(1,"cache 0 was not invalidated");

    // Simultaneous stores must serialize without deadlock.
    fork
      access(0,1,32'h100,32'h4444_4444,0);
      access(1,1,32'h104,32'h5555_5555,0);
    join
    access(0,0,32'h104,0,32'h5555_5555);
    access(1,0,32'h100,0,32'h4444_4444);
    $display("tb_coherence: PASS");
    $finish;
  end
endmodule
