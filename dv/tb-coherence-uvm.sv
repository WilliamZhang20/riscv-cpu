`include "uvm_macros.svh"
import uvm_pkg::*;

class coh_item extends uvm_sequence_item;
  rand bit [31:0] addr;
  `uvm_object_utils_begin(coh_item)
    `uvm_field_int(addr, UVM_HEX)
  `uvm_object_utils_end
  function new(string name="coh_item"); super.new(name); endfunction
endclass

class coh_seq extends uvm_sequence #(coh_item);
  `uvm_object_utils(coh_seq)
  bit [31:0] base_addr;
  function new(string name="coh_seq"); super.new(name); endfunction
  task body();
    coh_item item = coh_item::type_id::create("item");
    start_item(item); item.addr = base_addr; finish_item(item);
  endtask
endclass

class coh_driver extends uvm_driver #(coh_item);
  `uvm_component_utils(coh_driver)
  virtual coherence_if vif;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    vif.req_valid <= 1'b0;
    vif.req_addr  <= '0;
    vif.ack_ready <= 1'b1;
    vif.inv_ready <= 1'b1;
    forever begin
      seq_item_port.get_next_item(req);
      vif.req_addr <= req.addr; vif.req_valid <= 1'b1;
      do @(posedge vif.clk); while (!vif.req_ready);
      vif.req_valid <= 1'b0;
      repeat (4) @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

class coh_monitor extends uvm_monitor;
  `uvm_component_utils(coh_monitor)
  virtual coherence_if vif;
  int source_id;
  uvm_analysis_port #(coh_item) ap;
  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap",this);
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      #1;
      if (vif.inv_valid && vif.inv_ready) begin
        coh_item item = coh_item::type_id::create("invalidation");
        item.addr = vif.inv_addr;
        `uvm_info("COH_MON", $sformatf("cache%0d invalidated %08h",source_id,item.addr), UVM_MEDIUM)
        ap.write(item);
      end
    end
  endtask
endclass

class coh_agent extends uvm_agent;
  `uvm_component_utils(coh_agent)
  uvm_sequencer #(coh_item) sequencer;
  coh_driver driver;
  coh_monitor monitor;
  virtual coherence_if vif;
  int source_id;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual coherence_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","coherence virtual interface missing")
    sequencer=uvm_sequencer#(coh_item)::type_id::create("sequencer",this);
    driver=coh_driver::type_id::create("driver",this);
    monitor=coh_monitor::type_id::create("monitor",this);
    driver.vif=vif; monitor.vif=vif; monitor.source_id=source_id;
  endfunction
  function void connect_phase(uvm_phase phase); driver.seq_item_port.connect(sequencer.seq_item_export); endfunction
endclass

class coh_scoreboard extends uvm_component;
  `uvm_component_utils(coh_scoreboard)
  int invalidations;
  uvm_analysis_imp #(coh_item,coh_scoreboard) imp[2];
  function new(string name, uvm_component parent);
    super.new(name,parent); imp[0]=new("imp0",this); imp[1]=new("imp1",this);
  endfunction
  function void write(coh_item item); invalidations++; endfunction
  function void check_phase(uvm_phase phase);
    if (invalidations < 2) `uvm_error("COH_SB",$sformatf("only %0d invalidations observed",invalidations))
    else `uvm_info("COH_SB",$sformatf("observed %0d invalidations",invalidations),UVM_LOW)
  endfunction
endclass

class coh_env extends uvm_env;
  `uvm_component_utils(coh_env)
  coh_agent agent[2]; coh_scoreboard scoreboard;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    for (int i=0;i<2;i++) begin agent[i]=coh_agent::type_id::create($sformatf("agent%0d",i),this); agent[i].source_id=i; end
    scoreboard=coh_scoreboard::type_id::create("scoreboard",this);
  endfunction
  function void connect_phase(uvm_phase phase);
    agent[0].monitor.ap.connect(scoreboard.imp[0]); agent[1].monitor.ap.connect(scoreboard.imp[1]);
  endfunction
endclass

class multicore_coh_test extends uvm_test;
  `uvm_component_utils(multicore_coh_test)
  coh_env env;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase); super.build_phase(phase); env=coh_env::type_id::create("env",this); endfunction
  task run_phase(uvm_phase phase);
    coh_seq s0, s1;
    s0 = coh_seq::type_id::create("s0");
    s1 = coh_seq::type_id::create("s1");
    phase.raise_objection(this); s0.base_addr=32'h100; s1.base_addr=32'h104;
    fork s0.start(env.agent[0].sequencer); s1.start(env.agent[1].sequencer); join
    phase.drop_objection(this);
  endtask
endclass

module tb_coherence_uvm;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  coherence_if coh[2](clk,rst_n);
  coherence_hub #(.NUM_CACHES(2)) dut(.clk(clk),.rst_n(rst_n),.cache_port(coh));
  initial begin
    uvm_config_db#(virtual coherence_if)::set(null,"uvm_test_top.env.agent0","vif",coh[0]);
    uvm_config_db#(virtual coherence_if)::set(null,"uvm_test_top.env.agent1","vif",coh[1]);
    run_test("multicore_coh_test");
  end
  initial begin
    repeat(3) @(posedge clk);
    rst_n <= 1'b1;
  end
endmodule
