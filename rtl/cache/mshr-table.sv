// Small synthesizable MSHR table. The cache controller owns refill data and
// waiters; this block only tracks transaction identity and line metadata.
module mshr_table #(
    parameter int unsigned ENTRIES=4,
    parameter int unsigned ID_W=4,
    parameter int unsigned ADDR_W=32
) (
    input logic clk, input logic rst_n,
    input logic alloc_valid, output logic alloc_ready,
    input logic [ID_W-1:0] alloc_id,
    input logic [ADDR_W-1:0] alloc_line,
    output logic alloc_fire,
    input logic rsp_valid, input logic [ID_W-1:0] rsp_id,
    output logic rsp_hit,
    output logic [ADDR_W-1:0] rsp_line,
    input logic free_valid, input logic [ID_W-1:0] free_id
);
  logic valid_q [ENTRIES];
  logic [ID_W-1:0] id_q [ENTRIES];
  logic [ADDR_W-1:0] line_q [ENTRIES];
  localparam int unsigned SLOT_W = (ENTRIES <= 1) ? 1 : $clog2(ENTRIES);
  logic [SLOT_W-1:0] alloc_slot, rsp_slot;
  logic free_slot_valid, rsp_slot_valid;
  assign alloc_ready = free_slot_valid;
  assign alloc_fire = alloc_valid && alloc_ready;
  assign rsp_hit = rsp_slot_valid;
  assign rsp_line = rsp_slot_valid ? line_q[rsp_slot] : '0;
  always_comb begin
    free_slot_valid=1'b0; alloc_slot='0; rsp_slot='0; rsp_slot_valid=1'b0;
    for (int i=0;i<ENTRIES;i++) begin
      if (!valid_q[i] && !free_slot_valid) begin
        free_slot_valid=1'b1; alloc_slot=SLOT_W'(i);
      end
      if (valid_q[i] && id_q[i] == rsp_id) begin rsp_slot_valid=1'b1; rsp_slot=SLOT_W'(i); end
    end
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<ENTRIES;i++) valid_q[i] <= 1'b0;
    end else begin
      if (alloc_fire) begin
        valid_q[alloc_slot] <= 1'b1;
        id_q[alloc_slot] <= alloc_id;
        line_q[alloc_slot] <= alloc_line;
      end
      if (free_valid) begin
        for (int i=0;i<ENTRIES;i++)
          if (valid_q[i] && id_q[i] == free_id) valid_q[i] <= 1'b0;
      end
    end
  end
`ifndef SYNTHESIS
  always_ff @(posedge clk) if (rst_n) begin
    for (int i=0;i<ENTRIES;i++) for (int j=i+1;j<ENTRIES;j++)
      assert (!(valid_q[i] && valid_q[j] && id_q[i] == id_q[j]))
        else $error("MSHR transaction IDs must be unique");
  end
`endif
endmodule : mshr_table
