module tb_wb_msi_cache;
  logic clk = 0, rst_n = 0;
  mem_if cpu0(clk, rst_n), cpu1(clk, rst_n);
  mem_if mem0(clk, rst_n), mem1(clk, rst_n);
  msi_coherence_if coh[2](clk, rst_n);
  logic [31:0] backing [0:1023];
  logic pend0, pend1;
  logic [31:0] addr0_q, addr1_q;
  int i;

  always #5 clk = ~clk;
  wb_msi_cache c0(.cpu(cpu0), .memory(mem0), .coherence(coh[0]));
  wb_msi_cache c1(.cpu(cpu1), .memory(mem1), .coherence(coh[1]));
  msi_coherence_hub #(.NUM_CACHES(2)) hub(.clk(clk), .rst_n(rst_n), .cache_port(coh));

  assign mem0.req_ready = !pend0;
  assign mem1.req_ready = !pend1;
  assign mem0.rsp_valid = pend0;
  assign mem1.rsp_valid = pend1;
  assign mem0.rsp_rdata = backing[addr0_q[11:2]];
  assign mem1.rsp_rdata = backing[addr1_q[11:2]];
  assign mem0.rsp_error = 1'b0;
  assign mem1.rsp_error = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pend0 <= 1'b0; pend1 <= 1'b0; addr0_q <= '0; addr1_q <= '0;
    end else begin
      if (mem0.req_valid && mem0.req_ready) begin
        pend0 <= 1'b1; addr0_q <= mem0.req_addr;
        if (mem0.req_write) backing[mem0.req_addr[11:2]] <= mem0.req_wdata;
      end else if (mem0.rsp_valid && mem0.rsp_ready) pend0 <= 1'b0;
      if (mem1.req_valid && mem1.req_ready) begin
        pend1 <= 1'b1; addr1_q <= mem1.req_addr;
        if (mem1.req_write) backing[mem1.req_addr[11:2]] <= mem1.req_wdata;
      end else if (mem1.rsp_valid && mem1.rsp_ready) pend1 <= 1'b0;
    end
  end

  task automatic cpu_write(input logic which, input logic [31:0] addr,
                           input logic [31:0] data);
    begin
      if (!which) begin
        cpu0.req_addr=addr; cpu0.req_write=1; cpu0.req_wdata=data; cpu0.req_be=4'hf; cpu0.req_valid=1;
        do @(posedge clk); while (!cpu0.req_ready);
        @(negedge clk); cpu0.req_valid=0; cpu0.rsp_ready=1;
        do @(posedge clk); while (!cpu0.rsp_valid);
        if (cpu0.rsp_error) $fatal(1,"cache 0 store failed");
        @(negedge clk); cpu0.rsp_ready=0;
      end else begin
        cpu1.req_addr=addr; cpu1.req_write=1; cpu1.req_wdata=data; cpu1.req_be=4'hf; cpu1.req_valid=1;
        do @(posedge clk); while (!cpu1.req_ready);
        @(negedge clk); cpu1.req_valid=0; cpu1.rsp_ready=1;
        do @(posedge clk); while (!cpu1.rsp_valid);
        if (cpu1.rsp_error) $fatal(1,"cache 1 store failed");
        @(negedge clk); cpu1.rsp_ready=0;
      end
    end
  endtask

  task automatic cpu_read1(input logic [31:0] addr, output logic [31:0] data);
    begin
      cpu1.req_addr=addr; cpu1.req_write=0; cpu1.req_wdata='0; cpu1.req_be=4'hf; cpu1.req_valid=1;
      do @(posedge clk); while (!cpu1.req_ready);
      @(negedge clk); cpu1.req_valid=0; cpu1.rsp_ready=1;
      do @(posedge clk); while (!cpu1.rsp_valid);
      data=cpu1.rsp_rdata;
      if (cpu1.rsp_error) $fatal(1,"cache 1 load failed");
      @(negedge clk); cpu1.rsp_ready=0;
    end
  endtask

  logic [31:0] observed;
  initial begin
    for (i=0;i<1024;i++) backing[i]=32'hdead_beef;
    cpu0.req_valid=0; cpu0.rsp_ready=0; cpu1.req_valid=0; cpu1.rsp_ready=0;
    repeat (2) @(negedge clk); rst_n=1;
    cpu_write(1'b0, 32'h0000_0100, 32'h1234_5678);
    // 0x120, 0x320, and 0x520 map to the same set with three tags.
    cpu_write(1'b0, 32'h0000_0120, 32'hcafe_babe);
    cpu_write(1'b0, 32'h0000_0320, 32'h1111_2222);
    cpu_write(1'b0, 32'h0000_0520, 32'h3333_4444);
    if (backing[32'h120 >> 2] !== 32'hcafe_babe)
      $fatal(1,"dirty eviction did not update backing memory: %h", backing[32'h120 >> 2]);
    cpu_read1(32'h0000_0100, observed);
    if (observed !== 32'h1234_5678)
      $fatal(1,"dirty cache-to-cache transfer lost data: %h", observed);
    $display("tb_wb_msi_cache: PASS (dirty MSI transfer)");
    $finish;
  end
endmodule
