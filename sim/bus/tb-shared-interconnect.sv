// ============================================================================
// Standalone shared-interconnect test.
// ============================================================================
module tb_shared_interconnect;

  localparam int NUM_MASTERS = 2;
  localparam logic [31:0] ADDR_A = 32'h0000_0010;
  localparam logic [31:0] ADDR_B = 32'h0000_0020;
  localparam logic [31:0] ADDR_C = 32'h0000_0110;
  localparam logic [31:0] ADDR_BAD = 32'h0000_0300;

  logic clk = 1'b0;
  logic rst_n = 1'b0;

  always #5 clk = ~clk;

  mem_if master_if [NUM_MASTERS](clk, rst_n);
  mem_if slave_if [2](clk, rst_n);

  logic                  req_valid [NUM_MASTERS];
  logic [31:0]           req_addr [NUM_MASTERS];
  logic                  req_write [NUM_MASTERS];
  logic [31:0]           req_wdata [NUM_MASTERS];
  logic [3:0]            req_be [NUM_MASTERS];
  logic                  req_ready [NUM_MASTERS];
  logic                  rsp_valid [NUM_MASTERS];
  logic [31:0]           rsp_rdata [NUM_MASTERS];
  logic                  rsp_error [NUM_MASTERS];
  logic                  rsp_ready [NUM_MASTERS];

  generate
    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_master_signals
      assign master_if[m].req_valid = req_valid[m];
      assign master_if[m].req_addr  = req_addr[m];
      assign master_if[m].req_write = req_write[m];
      assign master_if[m].req_wdata = req_wdata[m];
      assign master_if[m].req_be    = req_be[m];
      assign req_ready[m]          = master_if[m].req_ready;
      assign rsp_valid[m]          = master_if[m].rsp_valid;
      assign rsp_rdata[m]          = master_if[m].rsp_rdata;
      assign rsp_error[m]          = master_if[m].rsp_error;
      assign master_if[m].rsp_ready = rsp_ready[m];
    end
  endgenerate

  noc_fabric #(
      .NUM_MASTERS (NUM_MASTERS),
      .NUM_SLAVES  (2),
      .SLAVE_BASE  ({32'h0000_0100, 32'h0000_0000}),
      .SLAVE_LIMIT ({32'h0000_01FF, 32'h0000_00FF})
  ) u_interconnect (
      .clk         (clk),
      .rst_n       (rst_n),
      .master_port (master_if),
      .slave_port  (slave_if)
  );

  sync_memory #(
      .MEM_BYTES (256)
  ) u_memory0 (
      .bus (slave_if[0])
  );

  sync_memory #(
      .MEM_BYTES (256),
      .BASE_ADDR (32'h0000_0100)
  ) u_memory1 (
      .bus (slave_if[1])
  );

  task automatic init_master(input int m);
    req_valid[m] = 1'b0;
    req_addr[m]  = '0;
    req_write[m] = 1'b0;
    req_wdata[m] = '0;
    req_be[m]    = '0;
    rsp_ready[m] = 1'b1;
  endtask

  task automatic write_word(input int m, input logic [31:0] addr,
                            input logic [31:0] data);
    req_valid[m] = 1'b1;
    req_addr[m]  = addr;
    req_write[m] = 1'b1;
    req_wdata[m] = data;
    req_be[m]    = 4'b1111;

    @(negedge clk);
    while (!req_ready[m]) @(negedge clk);
    @(posedge clk);
    #1;
    req_valid[m] = 1'b0;
    @(negedge clk);
    while (!rsp_valid[m]) @(negedge clk);
    @(posedge clk);
  endtask

  task automatic read_word(input int m, input logic [31:0] addr,
                           input logic [31:0] expected);
    req_valid[m] = 1'b1;
    req_addr[m]  = addr;
    req_write[m] = 1'b0;
    req_wdata[m] = '0;
    req_be[m]    = 4'b1111;

    @(negedge clk);
    while (!req_ready[m]) @(negedge clk);
    @(posedge clk);
    #1;
    req_valid[m] = 1'b0;
    @(negedge clk);
    while (!rsp_valid[m]) @(negedge clk);
    @(posedge clk);
    if (rsp_error[m] || rsp_rdata[m] !== expected)
      $fatal(1, "read mismatch: master=%0d addr=%08h got=%08h err=%b",
             m, addr, rsp_rdata[m], rsp_error[m]);
  endtask

  task automatic read_error(input int m, input logic [31:0] addr);
    req_valid[m] = 1'b1;
    req_addr[m]  = addr;
    req_write[m] = 1'b0;
    req_wdata[m] = '0;
    req_be[m]    = 4'b1111;

    @(negedge clk);
    while (!req_ready[m]) @(negedge clk);
    @(posedge clk);
    #1;
    req_valid[m] = 1'b0;
    @(negedge clk);
    while (!rsp_valid[m]) @(negedge clk);
    if (!rsp_error[m])
      $fatal(1, "unmapped address did not return an error: %08h", addr);
    @(posedge clk);
  endtask

  task automatic read_word_stalled(input int m, input logic [31:0] addr,
                                    input logic [31:0] expected);
    rsp_ready[m] = 1'b0;
    req_valid[m] = 1'b1;
    req_addr[m]  = addr;
    req_write[m] = 1'b0;
    req_wdata[m] = '0;
    req_be[m]    = 4'b1111;

    @(negedge clk);
    while (!req_ready[m]) @(negedge clk);
    @(posedge clk);
    #1;
    req_valid[m] = 1'b0;
    @(negedge clk);
    while (!rsp_valid[m]) @(negedge clk);

    repeat (2) begin
      if (!rsp_valid[m] || rsp_rdata[m] !== expected)
        $fatal(1, "stalled response changed or disappeared: master=%0d", m);
      @(negedge clk);
    end

    rsp_ready[m] = 1'b1;
    @(posedge clk);
  endtask

  initial begin
    init_master(0);
    init_master(1);

    repeat (2) @(posedge clk);
    rst_n <= 1'b1;
    @(negedge clk);

    // Both masters contend for the same slave. The first request is selected
    // by the initial round-robin pointer; the second follows after the first
    // response releases the shared target.
    fork
      write_word(0, ADDR_A, 32'hAAAA_0000);
      write_word(1, ADDR_C, 32'hCCCC_0002);
    join

    read_word(0, ADDR_C, 32'hCCCC_0002);
    read_word(1, ADDR_A, 32'hAAAA_0000);
    read_word_stalled(0, ADDR_A, 32'hAAAA_0000);
    read_error(0, ADDR_BAD);

    $display("tb_shared_interconnect: PASS");
    $finish;
  end

endmodule : tb_shared_interconnect
