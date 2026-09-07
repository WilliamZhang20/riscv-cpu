module tb_l1d_nb_cache;
  logic clk=0, rst_n=0;
  tagged_mem_if cpu(clk,rst_n), memory(clk,rst_n);
  logic pending[2]; logic [31:0] pending_addr[2];
  logic [31:0] expect0, expect1;
  int responses;

  always #5 clk=~clk;
  l1d_nb_cache #(.CACHE_BYTES(1024),.LINE_BYTES(16),.MSHR_COUNT(2)) dut(.cpu(cpu),.memory(memory));

  assign memory.req_ready=!memory.rsp_valid;
  always_comb begin
    memory.rsp_valid=1'b0; memory.rsp_id='0; memory.rsp_rdata='0; memory.rsp_error=1'b0;
    if (pending[1]) begin
      memory.rsp_valid=1'b1; memory.rsp_id=1;
      memory.rsp_rdata=pending_addr[1] ^ 32'hA5A5_0000;
    end else if (pending[0]) begin
      memory.rsp_valid=1'b1; memory.rsp_id=0;
      memory.rsp_rdata=pending_addr[0] ^ 32'hA5A5_0000;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending[0]<=0; pending[1]<=0; pending_addr[0]<='0; pending_addr[1]<='0;
    end else begin
      if (memory.req_valid && memory.req_ready) begin
        pending[memory.req_id[0]]<=1;
        pending_addr[memory.req_id[0]]<=memory.req_addr;
      end
      if (memory.rsp_valid && memory.rsp_ready) pending[memory.rsp_id[0]]<=0;
    end
  end

  always @(posedge clk) begin
    if (rst_n && cpu.rsp_valid && cpu.rsp_ready) begin
      if (cpu.rsp_id == 4'h4 && cpu.rsp_rdata !== expect0) $fatal(1,"miss 0 data/tag mismatch: got %h expected %h",cpu.rsp_rdata,expect0);
      if (cpu.rsp_id == 4'h9 && cpu.rsp_rdata !== expect1) $fatal(1,"miss 1 data/tag mismatch: got %h expected %h",cpu.rsp_rdata,expect1);
      responses++;
    end
  end

  task automatic request(input logic [3:0] id, input logic [31:0] addr);
    cpu.req_id=id; cpu.req_addr=addr; cpu.req_write=0; cpu.req_wdata=0; cpu.req_be='1; cpu.req_valid=1;
    while (!cpu.req_ready) @(negedge clk);
    @(posedge clk); #1 cpu.req_valid=0;
  endtask

  initial begin
    cpu.req_valid=0; cpu.req_id=0; cpu.req_addr=0; cpu.req_write=0; cpu.req_wdata=0; cpu.req_be='1;
    cpu.rsp_ready=1; responses=0;
    repeat(2) @(negedge clk); rst_n=1;
    expect0=32'h108 ^ 32'hA5A5_0000; expect1=32'h208 ^ 32'hA5A5_0000;
    request(4'h4,32'h108); request(4'h9,32'h208);
    fork
      begin #2000 $fatal(1,"two-MSHR refill test timed out"); end
    join_none
    wait(responses==2); #1;
    $display("tb_l1d_nb_cache: PASS (out-of-order refill responses)"); $finish;
  end
endmodule
