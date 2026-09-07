# ============================================================================
# sim/Makefile -- build and run the baseline core testbench.
#
#   make            build + run test-basic
#   make trace      run with a per-instruction trace
#   make waves      run and dump waves.vcd
#   make clean
#
# PATH is set explicitly rather than relying on ~/.bashrc: make recipes run in
# non-interactive shells, which never read it. See the top-level README.
# ============================================================================
VERILATOR_PREFIX ?= $(HOME)/.local/verilator-5.050
VERILATOR        := $(VERILATOR_PREFIX)/bin/verilator
export VERILATOR_ROOT := $(VERILATOR_PREFIX)/share/verilator

RTL_DIR := ../rtl
# rv32i-pkg.sv must come first: everything else imports it.
SRCS := $(RTL_DIR)/rv32i-pkg.sv \
        $(RTL_DIR)/alu.sv \
        $(RTL_DIR)/register-file.sv \
        $(RTL_DIR)/imm-gen.sv \
        $(RTL_DIR)/branch-unit.sv \
        $(RTL_DIR)/control-unit.sv \
        $(RTL_DIR)/program-counter.sv \
        $(RTL_DIR)/bus/mem-if.sv \
        $(RTL_DIR)/bus/coherence-if.sv \
        $(RTL_DIR)/l1i-cache.sv \
        $(RTL_DIR)/l1d-cache.sv \
        $(RTL_DIR)/l2-cache.sv \
        $(RTL_DIR)/bus/coherence-hub.sv \
        $(RTL_DIR)/bus/shared-interconnect.sv \
        $(RTL_DIR)/memory/sync-memory.sv \
        $(RTL_DIR)/single-core.sv \
        tb-core.sv

TOP   := tb_core
BIN   := obj_dir/$(TOP)
PROG  ?= test-basic
FLAGS := --binary --timing --assert --timescale 1ns/1ps -Wno-DECLFILENAME

.PHONY: all run trace waves lint bus-lint bus-test bus-core-lint bus-core-test noc-test multicore-test interrupt-test dram-test axi-lite-test axi-multicore-lint nb-lint wb-msi-lint wb-msi-cache-test gpu-axi-lint gpu-axi-test gpu-engine-lint gpu-engine-test mshr-lint mshr-test l1d-nb-test dual-issue-test dual-decode-lint dual-decode-test dual-fetch-test regfile-2wide-test dual-slice-lint dual-slice-test dual-alu-core-lint dual-alu-core-test dual-rv32i-lint dual-rv32i-test dual-multicore-lint dual-multicore-test issue-scoreboard-test multicore-wb-msi-test uvm-test \
        l1i-lint l1i-test l1d-lint l1d-test coherence-test l2-lint multicore-lint regress clean
all: run

$(PROG).hex: $(PROG).s asm.py
	python3 asm.py $< $@

$(BIN): $(SRCS)
	$(VERILATOR) $(FLAGS) --top-module $(TOP) -o $(TOP) $(SRCS)

run: $(BIN) $(PROG).hex
	./$(BIN) +PROG=$(PROG).hex

trace: $(BIN) $(PROG).hex
	./$(BIN) +PROG=$(PROG).hex +TRACE

waves: $(SRCS) $(PROG).hex
	$(VERILATOR) $(FLAGS) --trace --top-module $(TOP) -o $(TOP) $(SRCS)
	./$(BIN) +PROG=$(PROG).hex +WAVES

lint:
	$(VERILATOR) --lint-only --timescale 1ns/1ps --top-module cpu_core \
	  $(BUS_CORE_SRCS)

BUS_SRCS := ../rtl/bus/mem-if.sv \
            ../rtl/bus/shared-interconnect.sv \
            ../rtl/bus/noc-fabric.sv \
            ../rtl/memory/sync-memory.sv \
            bus/tb-shared-interconnect.sv

noc-test: bus-test
bus-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_shared_interconnect -o tb_shared_interconnect $(BUS_SRCS)
	./obj_dir/tb_shared_interconnect

bus-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module shared_interconnect \
	  ../rtl/bus/mem-if.sv \
	  ../rtl/bus/shared-interconnect.sv \
            ../rtl/bus/noc-fabric.sv \
	  ../rtl/memory/sync-memory.sv

BUS_CORE_SRCS := ../rtl/rv32i-pkg.sv \
                 ../rtl/alu.sv \
                 ../rtl/register-file.sv \
                 ../rtl/imm-gen.sv \
                 ../rtl/branch-unit.sv \
                 ../rtl/control-unit.sv \
                 ../rtl/bus/mem-if.sv \
                 ../rtl/bus/shared-interconnect.sv \
            ../rtl/bus/noc-fabric.sv \
                 ../rtl/memory/sync-memory.sv \
                 ../rtl/single-core.sv

bus-core-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module cpu_core $(BUS_CORE_SRCS)

bus-core-test: $(PROG).hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_core_bus -o tb_core_bus $(BUS_CORE_SRCS) bus/tb-core-bus.sv
	./obj_dir/tb_core_bus +PROG=$(PROG).hex

L1I_SRCS := ../rtl/bus/mem-if.sv \
            ../rtl/l1i-cache.sv \
            cache/tb-l1i-cache.sv

l1i-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l1i_cache ../rtl/bus/mem-if.sv ../rtl/l1i-cache.sv

l1i-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_l1i_cache -o tb_l1i_cache $(L1I_SRCS)
	./obj_dir/tb_l1i_cache

L1D_SRCS := ../rtl/bus/mem-if.sv \
            ../rtl/bus/coherence-if.sv \
            ../rtl/l1d-cache.sv \
            ../rtl/bus/coherence-hub.sv \
            cache/tb-l1d-cache.sv

l1d-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l1d_cache ../rtl/bus/mem-if.sv \
	  ../rtl/bus/coherence-if.sv ../rtl/l1d-cache.sv

l1d-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_l1d_cache -o tb_l1d_cache $(L1D_SRCS)
	./obj_dir/tb_l1d_cache

coherence-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_coherence -o tb_coherence ../rtl/bus/mem-if.sv \
	  ../rtl/bus/coherence-if.sv ../rtl/l1d-cache.sv \
	  ../rtl/bus/coherence-hub.sv ../rtl/bus/shared-interconnect.sv \
            ../rtl/bus/noc-fabric.sv \
	  ../rtl/memory/sync-memory.sv cache/tb-coherence.sv
	./obj_dir/tb_coherence

l2-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l2_cache ../rtl/bus/mem-if.sv \
	  ../rtl/bus/coherence-if.sv ../rtl/l1d-cache.sv ../rtl/l2-cache.sv

multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv \
	  ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/bus/mem-if.sv \
	  ../rtl/bus/coherence-if.sv ../rtl/l1i-cache.sv ../rtl/l1d-cache.sv \
	  ../rtl/l2-cache.sv ../rtl/bus/coherence-hub.sv ../rtl/bus/shared-interconnect.sv \
            ../rtl/bus/noc-fabric.sv \
	  ../rtl/single-core.sv ../rtl/multicore.sv

nb-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_nb \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/bus/tagged-mem-if.sv ../rtl/bus/mem-tagged-bridge.sv ../rtl/bus/coherence-if.sv \
	  ../rtl/l1i-cache.sv ../rtl/cache/l1d-nb-cache.sv ../rtl/bus/shared-interconnect.sv ../rtl/bus/noc-fabric.sv \
	  ../rtl/single-core.sv ../rtl/multicore-nb.sv

wb-msi-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_wb_msi \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/bus/msi-coherence-if.sv ../rtl/bus/msi-coherence-hub.sv ../rtl/bus/coherence-if.sv \
	  ../rtl/l1i-cache.sv ../rtl/cache/wb-msi-cache.sv ../rtl/bus/shared-interconnect.sv ../rtl/bus/noc-fabric.sv \
	  ../rtl/single-core.sv ../rtl/multicore-wb-msi.sv

axi-multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_axi_lite \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv \
	  ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/bus/axi4-lite-if.sv ../rtl/bus/coherence-if.sv \
	  ../rtl/l1i-cache.sv ../rtl/l1d-cache.sv ../rtl/l2-cache.sv \
	  ../rtl/bus/coherence-hub.sv ../rtl/bus/shared-interconnect.sv \
	  ../rtl/bus/noc-fabric.sv ../rtl/memory/sync-memory.sv ../rtl/single-core.sv \
	  ../rtl/multicore.sv ../rtl/bus/mem-to-axi-lite.sv ../rtl/multicore-axi-lite.sv

gpu-axi-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module axi4_read_master ../rtl/bus/axi4-if.sv ../rtl/gpu/axi4-read-master.sv

gpu-axi-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_gpu_axi_read -o tb_gpu_axi_read ../rtl/bus/axi4-if.sv ../rtl/gpu/axi4-read-master.sv tb-gpu-axi-read.sv
	./obj_dir/tb_gpu_axi_read

gpu-engine-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module axi4_gpu_engine ../rtl/bus/axi4-lite-if.sv ../rtl/bus/axi4-if.sv ../rtl/gpu/axi4-read-master.sv ../rtl/gpu/axi4-gpu-engine.sv

gpu-engine-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/gpu_engine_tb --top-module tb_axi4_gpu_engine -o tb_axi4_gpu_engine ../rtl/bus/axi4-lite-if.sv ../rtl/bus/axi4-if.sv ../rtl/gpu/axi4-read-master.sv ../rtl/gpu/axi4-gpu-engine.sv tb-axi4-gpu-engine.sv
	./obj_dir/gpu_engine_tb/tb_axi4_gpu_engine

mshr-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module mshr_table ../rtl/cache/mshr-table.sv

mshr-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_mshr_table -o tb_mshr_table ../rtl/cache/mshr-table.sv tb-mshr-table.sv
	./obj_dir/tb_mshr_table

l1d-nb-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_l1d_nb_cache -o tb_l1d_nb_cache ../rtl/bus/tagged-mem-if.sv ../rtl/cache/l1d-nb-cache.sv tb-l1d-nb-cache.sv
	./obj_dir/tb_l1d_nb_cache

dual-issue-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_issue_alu -o tb_dual_issue_alu ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv tb-dual-issue-alu.sv
	./obj_dir/tb_dual_issue_alu

dual-decode-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_decode_execute \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv \
	  ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-decode-execute.sv

dual-decode-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_issue_decode_execute -o tb_dual_issue_decode_execute ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-decode-execute.sv tb-dual-issue-decode-execute.sv
	./obj_dir/tb_dual_issue_decode_execute

dual-fetch-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_fetch_pair -o tb_dual_fetch_pair ../rtl/bus/mem-if.sv ../rtl/core/dual-fetch-pair.sv tb-dual-fetch-pair.sv
	./obj_dir/tb_dual_fetch_pair

regfile-2wide-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/rf2wide --top-module tb_register_file_2wide -o tb_register_file_2wide ../rtl/rv32i-pkg.sv ../rtl/core/register-file-2wide.sv tb-register-file-2wide.sv
	./obj_dir/rf2wide/tb_register_file_2wide

dual-slice-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_core_slice \
	  ../rtl/bus/mem-if.sv ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv \
	  ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv \
	  ../rtl/core/dual-issue-decode-execute.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/dual-issue-core-slice.sv

dual-slice-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_slice_tb --top-module tb_dual_issue_core_slice -o tb_dual_issue_core_slice \
	  ../rtl/bus/mem-if.sv ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv \
	  ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv \
	  ../rtl/core/dual-issue-decode-execute.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/dual-issue-core-slice.sv tb-dual-issue-core-slice.sv
	./obj_dir/dual_slice_tb/tb_dual_issue_core_slice

dual-alu-core-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_alu_core ../rtl/bus/mem-if.sv ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-decode-execute.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/dual-issue-core-slice.sv ../rtl/core/dual-issue-alu-core.sv

dual-alu-core-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_alu_core_tb --top-module tb_dual_issue_alu_core -o tb_dual_issue_alu_core ../rtl/bus/mem-if.sv ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/control-unit.sv ../rtl/core/issue-scoreboard.sv ../rtl/core/dual-issue-alu.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-decode-execute.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/dual-issue-core-slice.sv ../rtl/core/dual-issue-alu-core.sv tb-dual-issue-alu-core.sv
	./obj_dir/dual_alu_core_tb/tb_dual_issue_alu_core

dual-rv32i-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_rv32i_core ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/bus/mem-if.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-rv32i-core.sv

dual-rv32i-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_rv32i_tb --top-module tb_dual_issue_rv32i_core -o tb_dual_issue_rv32i_core ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/bus/mem-if.sv ../rtl/memory/sync-memory.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-rv32i-core.sv tb-dual-issue-rv32i-core.sv
	./obj_dir/dual_rv32i_tb/tb_dual_issue_rv32i_core

dual-multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_dual_issue ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv ../rtl/bus/mem-if.sv ../rtl/bus/coherence-if.sv ../rtl/l1i-cache.sv ../rtl/l1d-cache.sv ../rtl/l2-cache.sv ../rtl/bus/coherence-hub.sv ../rtl/bus/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-rv32i-core.sv ../rtl/multicore-dual-issue.sv

dual-multicore-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/multicore_dual_issue_tb --top-module tb_multicore_dual_issue -o tb_multicore_dual_issue ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv ../rtl/bus/mem-if.sv ../rtl/bus/coherence-if.sv ../rtl/l1i-cache.sv ../rtl/l1d-cache.sv ../rtl/l2-cache.sv ../rtl/bus/coherence-hub.sv ../rtl/bus/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/core/dual-fetch-pair.sv ../rtl/core/register-file-2wide.sv ../rtl/core/dual-issue-rv32i-core.sv ../rtl/multicore-dual-issue.sv tb-multicore-dual-issue.sv
	./obj_dir/multicore_dual_issue_tb/tb_multicore_dual_issue

issue-scoreboard-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_issue_scoreboard -o tb_issue_scoreboard ../rtl/core/issue-scoreboard.sv tb-issue-scoreboard.sv
	./obj_dir/tb_issue_scoreboard

wb-msi-cache-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/wb_msi_cache_tb --top-module tb_wb_msi_cache -o tb_wb_msi_cache ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv ../rtl/bus/mem-if.sv ../rtl/bus/msi-coherence-if.sv ../rtl/bus/msi-coherence-hub.sv ../rtl/cache/wb-msi-cache.sv tb-wb-msi-cache.sv
	./obj_dir/wb_msi_cache_tb/tb_wb_msi_cache

multicore-wb-msi-test: test-basic.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_multicore_wb_msi -o tb_multicore_wb_msi \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/bus/msi-coherence-if.sv ../rtl/bus/msi-coherence-hub.sv ../rtl/bus/coherence-if.sv \
	  ../rtl/l1i-cache.sv ../rtl/cache/wb-msi-cache.sv ../rtl/bus/shared-interconnect.sv ../rtl/bus/noc-fabric.sv \
	  ../rtl/single-core.sv ../rtl/multicore-wb-msi.sv ../rtl/memory/sync-memory.sv tb-multicore-wb-msi.sv
	./obj_dir/tb_multicore_wb_msi +PROG=$(PROG).hex

regress: lint bus-lint l1i-lint l1d-lint l2-lint multicore-lint axi-multicore-lint nb-lint wb-msi-lint \
         gpu-axi-lint gpu-axi-test gpu-engine-lint gpu-engine-test mshr-lint mshr-test l1d-nb-test wb-msi-cache-test dual-issue-test dual-decode-lint dual-decode-test dual-fetch-test regfile-2wide-test dual-slice-lint dual-slice-test dual-alu-core-lint dual-alu-core-test dual-rv32i-lint dual-rv32i-test dual-multicore-lint dual-multicore-test bus-test l1i-test l1d-test coherence-test noc-test \
         multicore-test multicore-wb-msi-test issue-scoreboard-test interrupt-test \
         dram-test axi-lite-test run

dram-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps -Wno-fatal -Wno-UNSIGNED --top-module tb_dram -o tb_dram ../rtl/bus/mem-if.sv ../rtl/memory/dram-model.sv tb-dram.sv
	./obj_dir/tb_dram

axi-lite-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps -Wno-fatal --top-module tb_axi_lite -o tb_axi_lite ../rtl/bus/mem-if.sv ../rtl/bus/axi4-lite-if.sv ../rtl/bus/mem-to-axi-lite.sv tb-axi-lite.sv
	./obj_dir/tb_axi_lite

interrupt-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_interrupt -o tb_interrupt \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/single-core.sv ../rtl/bus/shared-interconnect.sv ../rtl/memory/sync-memory.sv tb-interrupt.sv
	./obj_dir/tb_interrupt

multicore-test: $(PROG).hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_multicore -o tb_multicore \
	  ../rtl/rv32i-pkg.sv ../rtl/alu.sv ../rtl/register-file.sv ../rtl/imm-gen.sv ../rtl/branch-unit.sv ../rtl/control-unit.sv ../rtl/program-counter.sv \
	  ../rtl/bus/mem-if.sv ../rtl/bus/coherence-if.sv ../rtl/l1i-cache.sv ../rtl/l1d-cache.sv ../rtl/l2-cache.sv ../rtl/bus/coherence-hub.sv \
	  ../rtl/bus/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/single-core.sv ../rtl/multicore.sv tb-multicore.sv
	./obj_dir/tb_multicore +PROG=$(PROG).hex

UVM_HOME ?= ../dv/uvm-core
UVM_DPI  ?= ../dv/dpi

uvm-test:
	@if [ ! -f "$(UVM_HOME)/src/uvm_pkg.sv" ]; then \
		echo "UVM source missing: run 'git submodule update --init'"; \
		exit 2; \
	fi
	$(VERILATOR) --binary --timing --vpi --assert --timescale 1ns/1ps -Wno-fatal \
	  --build-jobs $$(nproc) --verilate-jobs $$(nproc) \
	  -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
	  --top-module tb_coherence_uvm -o tb_coherence_uvm \
	  -CFLAGS "-I$(UVM_DPI)" +incdir+$(UVM_HOME)/src \
	  $(UVM_HOME)/src/uvm_pkg.sv $(UVM_DPI)/uvm_dpi.cc \
	  ../rtl/bus/coherence-if.sv ../rtl/bus/coherence-hub.sv \
	  ../dv/tb-coherence-uvm.sv
	./obj_dir/tb_coherence_uvm

clean:
	rm -rf obj_dir *.hex *.vcd
