// Blocking write-back L1 data cache with MSI line states.
// This controller is the Phase 4 replacement path for the legacy write-through
// l1d_cache. It supports dirty eviction and cache-to-cache dirty-line grants.
module wb_msi_cache #(
    parameter int unsigned ADDR_W=32, parameter int unsigned DATA_W=32,
    parameter int unsigned CACHE_BYTES=1024, parameter int unsigned LINE_BYTES=16
) (
    mem_if.slave cpu, mem_if.master memory,
    msi_coherence_if.cache coherence
);
  localparam int unsigned WORD_BYTES=DATA_W/8;
  localparam int unsigned WORDS=LINE_BYTES/WORD_BYTES;
  localparam int unsigned LINES=CACHE_BYTES/LINE_BYTES;
  localparam int unsigned WAYS=2;
  localparam int unsigned SETS=LINES/WAYS;
  localparam int unsigned OFF_W=$clog2(LINE_BYTES);
  localparam int unsigned WORD_W=(WORDS<=1)?1:$clog2(WORDS);
  localparam int unsigned SET_W=(SETS<=1)?1:$clog2(SETS);
  localparam int unsigned TAG_W=ADDR_W-OFF_W-SET_W;
  localparam int unsigned LINE_W=LINE_BYTES*8;
  typedef enum logic [3:0] {IDLE,LOOKUP,EVICT_REQ,EVICT_RSP,ACQ,WAIT_GRANT,
                            REFILL_REQ,REFILL_RSP,WRITE_REQ,WRITE_RSP,RESP,
                            AFTER_GRANT} state_t;
  typedef enum logic [1:0] {MSI_I=2'b00,MSI_S=2'b01,MSI_M=2'b10} msi_state_t;
  state_t state_q;
  logic [TAG_W-1:0] tag_q[SETS][WAYS];
  logic [LINE_W-1:0] line_q[SETS][WAYS];
  msi_state_t state_line_q[SETS][WAYS];
  logic repl_q[SETS];
  logic [ADDR_W-1:0] req_addr_q;
  logic req_write_q;
  logic [DATA_W-1:0] req_wdata_q;
  logic [DATA_W/8-1:0] req_be_q;
  logic [SET_W-1:0] req_set;
  logic [TAG_W-1:0] req_tag;
  logic [WORD_W-1:0] req_word;
  logic hit; logic hit_way; logic victim_way; logic [SET_W-1:0] victim_set;
  logic [TAG_W-1:0] victim_tag;
  logic [WORD_W-1:0] beat_q;
  logic access_way_q;
  logic [DATA_W-1:0] rsp_data_q;
  logic rsp_error_q;
  logic grant_data_pending_q;

  assign req_set=req_addr_q[OFF_W +: SET_W];
  assign req_tag=req_addr_q[ADDR_W-1 -: TAG_W];
  assign req_word=req_addr_q[$clog2(WORD_BYTES) +: WORD_W];
  assign victim_set=req_set;
  assign victim_tag=tag_q[req_set][victim_way];
  assign hit=(state_line_q[req_set][0]!=MSI_I && tag_q[req_set][0]==req_tag) ||
             (state_line_q[req_set][1]!=MSI_I && tag_q[req_set][1]==req_tag);
  assign hit_way=(state_line_q[req_set][0]!=MSI_I && tag_q[req_set][0]==req_tag)?1'b0:1'b1;
  assign victim_way=(state_line_q[req_set][0]==MSI_I)?1'b0:
                    (state_line_q[req_set][1]==MSI_I)?1'b1:repl_q[req_set];

  assign cpu.req_ready=(state_q==IDLE);
  assign cpu.rsp_valid=(state_q==RESP);
  assign cpu.rsp_rdata=rsp_data_q;
  assign cpu.rsp_error=rsp_error_q;

  assign memory.req_valid=(state_q==EVICT_REQ)||(state_q==REFILL_REQ)||(state_q==WRITE_REQ);
  assign memory.req_addr=(state_q==EVICT_REQ) ?
      {victim_tag,req_set,{OFF_W{1'b0}}}+ADDR_W'(beat_q*WORD_BYTES) :
      (state_q==REFILL_REQ) ?
      {req_addr_q[ADDR_W-1:OFF_W],{OFF_W{1'b0}}}+ADDR_W'(beat_q*WORD_BYTES) :
      req_addr_q;
  assign memory.req_write=(state_q==EVICT_REQ)||(state_q==WRITE_REQ);
  assign memory.req_wdata=(state_q==EVICT_REQ) ?
      line_q[victim_set][victim_way][beat_q*DATA_W +: DATA_W] : req_wdata_q;
  assign memory.req_be=(state_q==EVICT_REQ)?{DATA_W/8{1'b1}}:req_be_q;
  assign memory.rsp_ready=(state_q==EVICT_RSP)||(state_q==REFILL_RSP)||(state_q==WRITE_RSP);

  assign coherence.acq_valid=(state_q==ACQ);
  assign coherence.acq_addr={req_addr_q[ADDR_W-1:OFF_W],{OFF_W{1'b0}}};
  assign coherence.acq_write=req_write_q;
  assign coherence.grant_ready=(state_q==WAIT_GRANT);
  always_comb begin
    coherence.snoop_ready=1'b0;
    coherence.snoop_dirty=1'b0;
    coherence.snoop_data='0;
    if (coherence.snoop_valid) begin
      coherence.snoop_ready=1'b1;
      for (int w=0;w<WORDS;w++)
        for (int way=0;way<WAYS;way++)
          if (state_line_q[coherence.snoop_addr[OFF_W +: SET_W]][way]!=MSI_I &&
              tag_q[coherence.snoop_addr[OFF_W +: SET_W]][way] ==
              coherence.snoop_addr[ADDR_W-1 -: TAG_W])
            begin
              coherence.snoop_dirty=(state_line_q[coherence.snoop_addr[OFF_W +: SET_W]][way]==MSI_M);
              coherence.snoop_data=line_q[coherence.snoop_addr[OFF_W +: SET_W]][way];
            end
    end
  end

  always_ff @(posedge cpu.clk or negedge cpu.rst_n) begin
    if (!cpu.rst_n) begin
      state_q<=IDLE; req_addr_q<='0; req_write_q<=0; req_wdata_q<='0;
      req_be_q<='0; beat_q<='0; access_way_q<=0; rsp_data_q<='0;
      rsp_error_q<=0; grant_data_pending_q<=0;
      for (int s=0;s<SETS;s++) begin repl_q[s]<=0; for (int w=0;w<WAYS;w++) state_line_q[s][w]<=MSI_I; end
    end else begin
      if (coherence.snoop_valid && coherence.snoop_ready) begin
        for (int s=0;s<SETS;s++) for (int w=0;w<WAYS;w++)
          if (state_line_q[s][w]!=MSI_I &&
              tag_q[s][w]==coherence.snoop_addr[ADDR_W-1 -: TAG_W] &&
              s==int'(coherence.snoop_addr[OFF_W +: SET_W]))
            // A dirty owner supplies a read grant, but remains responsible
            // for writeback until a later write acquisition or eviction.
            if (coherence.snoop_write || state_line_q[s][w] != MSI_M)
              state_line_q[s][w]<=MSI_I;
      end
      unique case (state_q)
        IDLE: if (cpu.req_valid && cpu.req_ready) begin
          req_addr_q<=cpu.req_addr; req_write_q<=cpu.req_write;
          req_wdata_q<=cpu.req_wdata; req_be_q<=cpu.req_be; state_q<=LOOKUP;
        end
        LOOKUP: begin
          if (hit && !req_write_q) begin
            rsp_data_q<=line_q[req_set][hit_way][req_word*DATA_W +: DATA_W];
            rsp_error_q<=0; repl_q[req_set]<=~hit_way; state_q<=RESP;
          end else if (hit && req_write_q && state_line_q[req_set][hit_way]==MSI_M) begin
            for (int b=0;b<DATA_W/8;b++) if (req_be_q[b])
              line_q[req_set][hit_way][req_word*DATA_W+8*b +: 8]<=req_wdata_q[8*b +: 8];
            state_q<=RESP; rsp_error_q<=0; rsp_data_q<='0;
          end else begin
            access_way_q<=hit?hit_way:victim_way;
            if (!hit && state_line_q[req_set][victim_way]==MSI_M) begin beat_q<=0; state_q<=EVICT_REQ; end
            else state_q<=ACQ;
          end
        end
        EVICT_REQ: if (memory.req_ready) state_q<=EVICT_RSP;
        EVICT_RSP: if (memory.rsp_valid && memory.rsp_ready) begin
          if (memory.rsp_error) begin rsp_error_q<=1; state_q<=RESP; end
          else if (beat_q==WORD_W'(WORDS-1)) begin state_line_q[req_set][victim_way]<=MSI_I; state_q<=ACQ; end
          else begin beat_q<=beat_q+1'b1; state_q<=EVICT_REQ; end
        end
        ACQ: if (coherence.acq_ready) state_q<=WAIT_GRANT;
        WAIT_GRANT: if (coherence.grant_valid) begin
          if (coherence.grant_data_valid) begin
            line_q[req_set][access_way_q]<=coherence.grant_data;
            tag_q[req_set][access_way_q]<=req_tag;
            state_line_q[req_set][access_way_q]<=req_write_q?MSI_M:MSI_S;
            grant_data_pending_q<=1; state_q<=AFTER_GRANT;
          end else begin beat_q<=0; state_q<=REFILL_REQ; end
        end
        REFILL_REQ: if (memory.req_ready) state_q<=REFILL_RSP;
        REFILL_RSP: if (memory.rsp_valid && memory.rsp_ready) begin
          if (memory.rsp_error) begin rsp_error_q<=1; state_q<=RESP; end
          else begin
            line_q[req_set][access_way_q][beat_q*DATA_W +: DATA_W]<=memory.rsp_rdata;
            if (beat_q==WORD_W'(WORDS-1)) begin tag_q[req_set][access_way_q]<=req_tag; state_line_q[req_set][access_way_q]<=req_write_q?MSI_M:MSI_S; state_q<=AFTER_GRANT; end
            else begin beat_q<=beat_q+1'b1; state_q<=REFILL_REQ; end
          end
        end
        AFTER_GRANT: begin
          if (req_write_q) begin
            for (int b=0;b<DATA_W/8;b++) if (req_be_q[b])
              line_q[req_set][access_way_q][req_word*DATA_W+8*b +: 8]<=req_wdata_q[8*b +: 8];
            state_line_q[req_set][access_way_q]<=MSI_M; rsp_data_q<='0;
          end else rsp_data_q<=line_q[req_set][access_way_q][req_word*DATA_W +: DATA_W];
          rsp_error_q<=0; repl_q[req_set]<=~access_way_q; state_q<=RESP;
        end
        RESP: if (cpu.rsp_ready) state_q<=IDLE;
        default: state_q<=IDLE;
      endcase
    end
  end
endmodule : wb_msi_cache
