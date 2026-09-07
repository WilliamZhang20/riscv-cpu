// Nonblocking read-mostly L1 cache with two outstanding miss entries.
// This Phase 3 controller uses tagged_mem_if so refills can complete out of
// order. Stores are rejected until the write-back/MSI controller replaces it.
module l1d_nb_cache #(
    parameter int unsigned ADDR_W=32, parameter int unsigned DATA_W=32,
    parameter int unsigned CACHE_BYTES=1024, parameter int unsigned LINE_BYTES=16,
    parameter int unsigned MSHR_COUNT=2
) (
    tagged_mem_if.slave cpu,
    tagged_mem_if.master memory
);
  localparam int unsigned WORD_BYTES=DATA_W/8;
  localparam int unsigned WORDS_PER_LINE=LINE_BYTES/WORD_BYTES;
  localparam int unsigned NUM_LINES=CACHE_BYTES/LINE_BYTES;
  localparam int unsigned WAYS=2;
  localparam int unsigned SETS=NUM_LINES/WAYS;
  localparam int unsigned OFFSET_W=$clog2(LINE_BYTES);
  localparam int unsigned WORD_W=(WORDS_PER_LINE<=1)?1:$clog2(WORDS_PER_LINE);
  localparam int unsigned INDEX_W=(SETS<=1)?1:$clog2(SETS);
  localparam int unsigned TAG_W=ADDR_W-OFFSET_W-INDEX_W;
  localparam int unsigned SLOT_W=(MSHR_COUNT<=1)?1:$clog2(MSHR_COUNT);
  typedef logic [DATA_W-1:0] word_t;
  logic [TAG_W-1:0] tag_q [SETS][WAYS];
  logic valid_q [SETS][WAYS];
  word_t data_q [SETS][WAYS][WORDS_PER_LINE];
  logic repl_q [SETS];
  logic m_valid_q [MSHR_COUNT], m_wait_q [MSHR_COUNT], m_done_q [MSHR_COUNT];
  logic [cpu.ID_W-1:0] m_id_q [MSHR_COUNT];
  logic [ADDR_W-1:0] m_line_q [MSHR_COUNT];
  logic [WORD_W-1:0] m_word_q [MSHR_COUNT], m_refill_q [MSHR_COUNT];
  logic [INDEX_W-1:0] m_set_q [MSHR_COUNT];
  word_t m_data_q [MSHR_COUNT]; logic m_error_q [MSHR_COUNT];
  logic hit; logic hit_way; logic [INDEX_W-1:0] req_set;
  logic [TAG_W-1:0] req_tag; logic [WORD_W-1:0] req_word;
  logic free_valid; logic [SLOT_W-1:0] free_slot;
  logic same_line_pending;
  logic selected_valid; logic [SLOT_W-1:0] selected_slot;
  logic [SLOT_W-1:0] rsp_slot;
  logic hit_resp_q; logic [cpu.ID_W-1:0] hit_id_q; word_t hit_data_q; logic hit_error_q;
  assign req_set=cpu.req_addr[OFFSET_W +: INDEX_W];
  assign req_tag=cpu.req_addr[ADDR_W-1 -: TAG_W];
  assign req_word=cpu.req_addr[$clog2(WORD_BYTES)+: WORD_W];
  assign rsp_slot=memory.rsp_id[SLOT_W-1:0];
  assign hit=(valid_q[req_set][0] && tag_q[req_set][0]==req_tag) ||
             (valid_q[req_set][1] && tag_q[req_set][1]==req_tag);
  assign hit_way=valid_q[req_set][0] && tag_q[req_set][0]==req_tag ? 1'b0:1'b1;
  always_comb begin
    free_valid=1'b0; free_slot='0; selected_valid=1'b0; selected_slot='0;
    for (int i=0;i<MSHR_COUNT;i++) begin
      if (!m_valid_q[i] && !free_valid) begin free_valid=1'b1; free_slot=SLOT_W'(i); end
      if (m_valid_q[i] && !m_wait_q[i] && !m_done_q[i] && !selected_valid) begin
        selected_valid=1'b1; selected_slot=SLOT_W'(i);
      end
    end
  end
  always_comb begin
    same_line_pending=1'b0;
    for (int i=0;i<MSHR_COUNT;i++)
      if (m_valid_q[i] && m_line_q[i] == {cpu.req_addr[ADDR_W-1:OFFSET_W],{OFFSET_W{1'b0}}})
        same_line_pending=1'b1;
  end
  assign cpu.req_ready=!hit_resp_q && !cpu.req_write && !same_line_pending && (hit || free_valid);
  assign cpu.rsp_valid=hit_resp_q;
  assign cpu.rsp_id=hit_id_q; assign cpu.rsp_rdata=hit_data_q; assign cpu.rsp_error=hit_error_q;
  assign memory.req_valid=selected_valid;
  assign memory.req_id=selected_valid ? cpu.ID_W'(selected_slot):'0;
  assign memory.req_addr=selected_valid ? m_line_q[selected_slot] +
                          ADDR_W'(m_refill_q[selected_slot]*WORD_BYTES):'0;
  assign memory.req_write=1'b0; assign memory.req_wdata='0; assign memory.req_be='1;
  assign memory.rsp_ready=1'b1;
  always_ff @(posedge cpu.clk or negedge cpu.rst_n) begin
    if (!cpu.rst_n) begin
      hit_resp_q<=1'b0;
      for (int s=0;s<SETS;s++) begin repl_q[s]<=1'b0; for (int w=0;w<WAYS;w++) valid_q[s][w]<=1'b0; end
      for (int i=0;i<MSHR_COUNT;i++) begin m_valid_q[i]<=1'b0; m_wait_q[i]<=1'b0; m_done_q[i]<=1'b0; end
    end else begin
      if (hit_resp_q && cpu.rsp_ready) hit_resp_q<=1'b0;
      if (cpu.req_valid && cpu.req_ready) begin
        if (hit) begin
          hit_resp_q<=1'b1; hit_id_q<=cpu.req_id; hit_data_q<=data_q[req_set][hit_way][req_word]; hit_error_q<=1'b0;
          repl_q[req_set]<=~hit_way;
        end else begin
          m_valid_q[free_slot]<=1'b1; m_wait_q[free_slot]<=1'b0; m_done_q[free_slot]<=1'b0;
          m_id_q[free_slot]<=cpu.req_id;
          m_line_q[free_slot]<={cpu.req_addr[ADDR_W-1:OFFSET_W],{OFFSET_W{1'b0}}};
          m_word_q[free_slot]<=req_word; m_refill_q[free_slot]<='0; m_error_q[free_slot]<=1'b0;
          m_set_q[free_slot]<=req_set;
        end
      end
      if (memory.req_valid && memory.req_ready) m_wait_q[selected_slot]<=1'b1;
      if (memory.rsp_valid && memory.rsp_ready) begin
        if (int'(memory.rsp_id) < MSHR_COUNT) begin
          m_wait_q[rsp_slot]<=1'b0;
          if (memory.rsp_error) begin m_done_q[rsp_slot]<=1'b1; m_error_q[rsp_slot]<=1'b1; end
          else begin
            data_q[m_set_q[rsp_slot]][0][m_refill_q[rsp_slot]]<=memory.rsp_rdata;
            m_data_q[rsp_slot]<= (m_refill_q[rsp_slot]==m_word_q[rsp_slot]) ? memory.rsp_rdata:m_data_q[rsp_slot];
            if (m_refill_q[rsp_slot]==WORD_W'(WORDS_PER_LINE-1)) begin
              tag_q[m_set_q[rsp_slot]][0]<=m_line_q[rsp_slot][ADDR_W-1 -: TAG_W];
              valid_q[m_set_q[rsp_slot]][0]<=1'b1; m_done_q[rsp_slot]<=1'b1;
            end else m_refill_q[rsp_slot]<=m_refill_q[rsp_slot]+1'b1;
          end
        end
      end
      for (int i=0;i<MSHR_COUNT;i++) begin
        if (m_valid_q[i] && m_done_q[i] && !hit_resp_q) begin
          hit_resp_q<=1'b1; hit_id_q<=m_id_q[i]; hit_data_q<=m_data_q[i]; hit_error_q<=m_error_q[i]; m_valid_q[i]<=1'b0;
        end
      end
    end
  end
endmodule : l1d_nb_cache
