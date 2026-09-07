module tb_register_file_2wide;
  logic clk=0;
  logic [4:0] rs1_0_addr,rs2_0_addr,rs1_1_addr,rs2_1_addr,rd0_addr,rd1_addr;
  logic [31:0] rs1_0_data,rs2_0_data,rs1_1_data,rs2_1_data,rd0_data,rd1_data;
  logic rd0_we,rd1_we;
  always #5 clk=~clk;
  register_file_2wide dut(.*);
  initial begin
    rs1_0_addr=0;rs2_0_addr=0;rs1_1_addr=0;rs2_1_addr=0;rd0_addr=0;rd1_addr=0;
    rd0_data=0;rd1_data=0;rd0_we=0;rd1_we=0;
    #1;
    if(rs1_0_data!==0 || rs2_1_data!==0) $fatal(1,"x0 read failed");
    rd0_addr=5; rd0_data=32'h1111; rd0_we=1;
    rd1_addr=6; rd1_data=32'h2222; rd1_we=1;
    rs1_0_addr=5; rs2_0_addr=6; rs1_1_addr=5; rs2_1_addr=6;
    #1;
    if(rs1_0_data!==32'h1111 || rs2_0_data!==32'h2222 ||
       rs1_1_data!==32'h1111 || rs2_1_data!==32'h2222)
      $fatal(1,"same-cycle write/read bypass failed");
    @(posedge clk); #1; rd0_we=0; rd1_we=0;
    if(rs1_0_data!==32'h1111 || rs2_0_data!==32'h2222) $fatal(1,"register write failed");
    $display("tb_register_file_2wide: PASS"); $finish;
  end
endmodule
