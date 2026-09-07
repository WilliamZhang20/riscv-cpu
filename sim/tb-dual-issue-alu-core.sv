module tb_dual_issue_alu_core;
  logic clk = 0, rst_n = 0;
  logic [31:0] fetch_pc;
  logic fetch_active;
  logic retire_valid0, retire_valid1;
  logic [4:0] retire_rd0, retire_rd1;
  logic [31:0] retire_data0, retire_data1;
  mem_if imem0(clk, rst_n), imem1(clk, rst_n);
  logic p0, p1;
  logic [31:0] d0, d1;
  int retired;

  always #5 clk = ~clk;
  dual_issue_alu_core dut(.*);
  assign imem0.req_ready = 1'b1;
  assign imem1.req_ready = 1'b1;
  assign imem0.rsp_valid = p0;
  assign imem1.rsp_valid = p1;
  assign imem0.rsp_rdata = d0;
  assign imem1.rsp_rdata = d1;
  assign imem0.rsp_error = 1'b0;
  assign imem1.rsp_error = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p0 <= 1'b0; p1 <= 1'b0; d0 <= 32'h13; d1 <= 32'h13;
    end else begin
      if (imem0.req_valid) begin
        p0 <= 1'b1;
        unique case (imem0.req_addr)
          32'd0:  d0 <= 32'h00A0_0093; // addi x1,x0,10
          32'd8:  d0 <= 32'h0050_0193; // addi x3,x0,5
          default: d0 <= 32'h0000_0013;
        endcase
      end
      if (imem1.req_valid) begin
        p1 <= 1'b1;
        unique case (imem1.req_addr)
          32'd4:  d1 <= 32'h0140_0113; // addi x2,x0,20
          32'd12: d1 <= 32'h0031_8233; // add x4,x3,x3
          default: d1 <= 32'h0000_0013;
        endcase
      end
      if (imem0.rsp_valid && imem0.rsp_ready) p0 <= 1'b0;
      if (imem1.rsp_valid && imem1.rsp_ready) p1 <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if (rst_n) begin
      if (retire_valid0) begin
        retired++;
        if ((retired == 0 && (retire_rd0 != 1 || retire_data0 != 10)) ||
            (retired == 2 && (retire_rd0 != 3 || retire_data0 != 5)))
          $fatal(1, "bad lane 0 retirement %0d rd=%0d data=%0d", retired, retire_rd0, retire_data0);
      end
      if (retire_valid1) begin
        retired++;
        if ((retired == 1 && (retire_rd1 != 2 || retire_data1 != 20)) ||
            (retired == 3 && (retire_rd1 != 4 || retire_data1 != 10)))
          $fatal(1, "bad lane 1 retirement %0d rd=%0d data=%0d", retired, retire_rd1, retire_data1);
      end
    end
  end

  initial begin
    retired = 0;
    repeat (2) @(negedge clk); rst_n = 1'b1;
    wait (retired == 4); #1;
    if (fetch_pc != 32'd16)
      $fatal(1, "core did not advance through two pairs: pc=%0d", fetch_pc, fetch_active);
    $display("tb_dual_issue_alu_core: PASS");
    $finish;
  end
endmodule
