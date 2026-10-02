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
export PERL5LIB := $(HOME)/.local/share/perl5:$(PERL5LIB)

RTL_DIR := ../rtl
CPU_DIR := $(RTL_DIR)/cpu/core
DUAL_DIR := $(RTL_DIR)/cpu/dual_issue
CACHE_DIR := $(RTL_DIR)/cache
IF_DIR := $(RTL_DIR)/interconnect/interfaces
BR_DIR := $(RTL_DIR)/interconnect/bridges
COH_DIR := $(RTL_DIR)/interconnect/coherence
NOC_DIR := $(RTL_DIR)/interconnect/noc
GPU_MEM_DIR := $(RTL_DIR)/gpu/memory
SOC_DIR := $(RTL_DIR)/soc
SOC_VAR_DIR := $(RTL_DIR)/soc/variants
# rv32i-pkg.sv must come first: everything else imports it.
SRCS := $(CPU_DIR)/rv32i-pkg.sv \
        $(CPU_DIR)/alu.sv \
        $(CPU_DIR)/register-file.sv \
        $(CPU_DIR)/imm-gen.sv \
        $(CPU_DIR)/branch-unit.sv \
        $(CPU_DIR)/control-unit.sv \
        $(CPU_DIR)/program-counter.sv \
        $(IF_DIR)/mem-if.sv \
        $(IF_DIR)/coherence-if.sv \
        $(CACHE_DIR)/l1i-cache.sv \
        $(CACHE_DIR)/l1d-cache.sv \
        $(CACHE_DIR)/l2-cache.sv \
        $(COH_DIR)/coherence-hub.sv \
        $(NOC_DIR)/shared-interconnect.sv \
        $(RTL_DIR)/memory/sync-memory.sv \
        $(CPU_DIR)/single-core.sv \
        tb-core.sv
# Canonical SoC sources (dual-issue + WB-MSI + L2 + NoC + banked DRAM + GPU).
SOC_SRCS := $(CPU_DIR)/rv32i-pkg.sv \
        $(CPU_DIR)/alu.sv \
        $(CPU_DIR)/imm-gen.sv \
        $(CPU_DIR)/branch-unit.sv \
        $(CPU_DIR)/control-unit.sv \
        $(IF_DIR)/mem-if.sv \
        $(IF_DIR)/axi4-if.sv \
        $(IF_DIR)/axi4-lite-if.sv \
        $(IF_DIR)/coherence-if.sv \
        $(IF_DIR)/msi-coherence-if.sv \
        $(CACHE_DIR)/l1i-cache.sv \
        $(CACHE_DIR)/l1d-cache.sv \
        $(CACHE_DIR)/wb-msi-cache.sv \
        $(CACHE_DIR)/l2-cache.sv \
        $(COH_DIR)/msi-coherence-hub.sv \
        $(NOC_DIR)/shared-interconnect.sv \
        $(NOC_DIR)/noc-fabric.sv \
        $(BR_DIR)/mem-gpu-mmio-router.sv \
        $(BR_DIR)/axi4-to-mem.sv \
        $(GPU_MEM_DIR)/axi4-span-writer.sv \
        $(RTL_DIR)/gpu/raster/rect-rasterizer.sv \
        $(RTL_DIR)/gpu/raster/triangle-setup.sv \
        $(RTL_DIR)/gpu/raster/triangle-rasterizer.sv \
        $(RTL_DIR)/gpu/gpu.sv \
        $(RTL_DIR)/memory/banked-dram.sv \
        $(DUAL_DIR)/dual-fetch-pair.sv \
        $(DUAL_DIR)/register-file-2wide.sv \
        $(DUAL_DIR)/dual-issue-rv32i-core.sv \
        $(SOC_DIR)/soc.sv

TOP   := tb_core
BIN   := obj_dir/$(TOP)
PROG  ?= test-basic
FLAGS := --binary --timing --assert --timescale 1ns/1ps -Wno-DECLFILENAME

.PHONY: all run trace waves lint bus-lint bus-test bus-core-lint bus-core-test noc-test multicore-test interrupt-test dram-test axi-lite-test axi-multicore-lint nb-lint wb-msi-lint wb-msi-cache-test gpu-axi-lint gpu-axi-test gpu-engine-lint gpu-engine-test primitive-gpu-lint primitive-gpu-test mshr-lint mshr-test l1d-nb-test dual-issue-test dual-decode-lint dual-decode-test dual-fetch-test regfile-2wide-test dual-slice-lint dual-slice-test dual-alu-core-lint dual-alu-core-test dual-rv32i-lint dual-rv32i-test dual-multicore-lint dual-multicore-test issue-scoreboard-test multicore-wb-msi-test uvm-test \
        l1i-lint l1i-test l1d-lint l1d-test coherence-test l2-lint multicore-lint regress clean \
        soc-lint soc-test bench-ilp bench-dcache bench-gpu bench-all axi-bridge-lint banked-dram-test
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

BUS_SRCS := ../rtl/interconnect/interfaces/mem-if.sv \
            ../rtl/interconnect/noc/shared-interconnect.sv \
            ../rtl/interconnect/noc/noc-fabric.sv \
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
	  ../rtl/interconnect/interfaces/mem-if.sv \
	  ../rtl/interconnect/noc/shared-interconnect.sv \
            ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/memory/sync-memory.sv

BUS_CORE_SRCS := ../rtl/cpu/core/rv32i-pkg.sv \
                 ../rtl/cpu/core/alu.sv \
                 ../rtl/cpu/core/register-file.sv \
                 ../rtl/cpu/core/imm-gen.sv \
                 ../rtl/cpu/core/branch-unit.sv \
                 ../rtl/cpu/core/control-unit.sv \
                 ../rtl/interconnect/interfaces/mem-if.sv \
                 ../rtl/interconnect/noc/shared-interconnect.sv \
            ../rtl/interconnect/noc/noc-fabric.sv \
                 ../rtl/memory/sync-memory.sv \
                 ../rtl/cpu/core/single-core.sv

bus-core-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module cpu_core $(BUS_CORE_SRCS)

bus-core-test: $(PROG).hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_core_bus -o tb_core_bus $(BUS_CORE_SRCS) bus/tb-core-bus.sv
	./obj_dir/tb_core_bus +PROG=$(PROG).hex

L1I_SRCS := ../rtl/interconnect/interfaces/mem-if.sv \
            ../rtl/cache/l1i-cache.sv \
            cache/tb-l1i-cache.sv

l1i-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l1i_cache ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cache/l1i-cache.sv

l1i-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_l1i_cache -o tb_l1i_cache $(L1I_SRCS)
	./obj_dir/tb_l1i_cache

L1D_SRCS := ../rtl/interconnect/interfaces/mem-if.sv \
            ../rtl/interconnect/interfaces/coherence-if.sv \
            ../rtl/cache/l1d-cache.sv \
            ../rtl/interconnect/coherence/coherence-hub.sv \
            cache/tb-l1d-cache.sv

l1d-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l1d_cache ../rtl/interconnect/interfaces/mem-if.sv \
	  ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1d-cache.sv

l1d-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_l1d_cache -o tb_l1d_cache $(L1D_SRCS)
	./obj_dir/tb_l1d_cache

coherence-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_coherence -o tb_coherence ../rtl/interconnect/interfaces/mem-if.sv \
	  ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1d-cache.sv \
	  ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/noc/shared-interconnect.sv \
            ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/memory/sync-memory.sv cache/tb-coherence.sv
	./obj_dir/tb_coherence

l2-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l2_cache ../rtl/interconnect/interfaces/mem-if.sv \
	  ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1d-cache.sv ../rtl/cache/l2-cache.sv

multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv \
	  ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/interconnect/interfaces/mem-if.sv \
	  ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-cache.sv \
	  ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/cache/wb-msi-cache.sv \
	  ../rtl/cache/l2-cache.sv ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/noc/shared-interconnect.sv \
	  ../rtl/interconnect/coherence/msi-coherence-hub.sv \
            ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/cpu/core/single-core.sv ../rtl/soc/variants/multicore-single-issue.sv

nb-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_nb \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/tagged-mem-if.sv ../rtl/interconnect/bridges/mem-tagged-bridge.sv ../rtl/interconnect/interfaces/coherence-if.sv \
	  ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-nb-cache.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/cpu/core/single-core.sv ../rtl/soc/variants/multicore-nb.sv

wb-msi-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_wb_msi \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/interconnect/coherence/msi-coherence-hub.sv ../rtl/interconnect/interfaces/coherence-if.sv \
	  ../rtl/cache/l1i-cache.sv ../rtl/cache/wb-msi-cache.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/cpu/core/single-core.sv ../rtl/soc/variants/multicore-wb-msi.sv

axi-multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_axi_lite \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv \
	  ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/axi4-lite-if.sv ../rtl/interconnect/interfaces/coherence-if.sv \
	  ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-cache.sv ../rtl/cache/wb-msi-cache.sv ../rtl/cache/l2-cache.sv \
	  ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/coherence/msi-coherence-hub.sv ../rtl/interconnect/noc/shared-interconnect.sv \
	  ../rtl/interconnect/noc/noc-fabric.sv ../rtl/memory/sync-memory.sv ../rtl/cpu/core/single-core.sv \
	  ../rtl/soc/variants/multicore-single-issue.sv ../rtl/interconnect/bridges/mem-to-axi-lite.sv ../rtl/soc/variants/multicore-axi-lite.sv

gpu-axi-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module axi4_read_master ../rtl/interconnect/interfaces/axi4-if.sv ../rtl/gpu/memory/axi4-read-master.sv

gpu-axi-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_gpu_axi_read -o tb_gpu_axi_read ../rtl/interconnect/interfaces/axi4-if.sv ../rtl/gpu/memory/axi4-read-master.sv tb-gpu-axi-read.sv
	./obj_dir/tb_gpu_axi_read

gpu-engine-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module axi4_gpu_engine ../rtl/interconnect/interfaces/axi4-lite-if.sv ../rtl/interconnect/interfaces/axi4-if.sv ../rtl/gpu/memory/axi4-read-master.sv ../rtl/gpu/memory/axi4-gpu-engine.sv

gpu-engine-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/gpu_engine_tb --top-module tb_axi4_gpu_engine -o tb_axi4_gpu_engine ../rtl/interconnect/interfaces/axi4-lite-if.sv ../rtl/interconnect/interfaces/axi4-if.sv ../rtl/gpu/memory/axi4-read-master.sv ../rtl/gpu/memory/axi4-gpu-engine.sv tb-axi4-gpu-engine.sv
	./obj_dir/gpu_engine_tb/tb_axi4_gpu_engine

PRIMITIVE_GPU_RTL := ../rtl/interconnect/interfaces/axi4-if.sv ../rtl/interconnect/interfaces/axi4-lite-if.sv \
	../rtl/gpu/memory/axi4-span-writer.sv ../rtl/gpu/raster/rect-rasterizer.sv \
	../rtl/gpu/raster/triangle-setup.sv ../rtl/gpu/raster/triangle-rasterizer.sv ../rtl/gpu/gpu.sv

primitive-gpu-lint:
	$(VERILATOR) -Wno-WIDTHEXPAND --lint-only --assert --timescale 1ns/1ps --top-module primitive_gpu_2d $(PRIMITIVE_GPU_RTL)

primitive-gpu-test:
	$(VERILATOR) -Wno-WIDTHEXPAND --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/primitive_gpu_tb --top-module tb_primitive_gpu_2d -o tb_primitive_gpu_2d $(PRIMITIVE_GPU_RTL) tb-primitive-gpu-2d.sv
	./obj_dir/primitive_gpu_tb/tb_primitive_gpu_2d

mshr-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module mshr_table ../rtl/cache/mshr-table.sv

mshr-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_mshr_table -o tb_mshr_table ../rtl/cache/mshr-table.sv tb-mshr-table.sv
	./obj_dir/tb_mshr_table

l1d-nb-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_l1d_nb_cache -o tb_l1d_nb_cache ../rtl/interconnect/interfaces/tagged-mem-if.sv ../rtl/cache/l1d-nb-cache.sv tb-l1d-nb-cache.sv
	./obj_dir/tb_l1d_nb_cache

dual-issue-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_issue_alu -o tb_dual_issue_alu ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv tb-dual-issue-alu.sv
	./obj_dir/tb_dual_issue_alu

dual-decode-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_decode_execute \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv \
	  ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv

dual-decode-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_issue_decode_execute -o tb_dual_issue_decode_execute ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv tb-dual-issue-decode-execute.sv
	./obj_dir/tb_dual_issue_decode_execute

dual-fetch-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_dual_fetch_pair -o tb_dual_fetch_pair ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv tb-dual-fetch-pair.sv
	./obj_dir/tb_dual_fetch_pair

regfile-2wide-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/rf2wide --top-module tb_register_file_2wide -o tb_register_file_2wide ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/dual_issue/register-file-2wide.sv tb-register-file-2wide.sv
	./obj_dir/rf2wide/tb_register_file_2wide

dual-slice-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_core_slice \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv \
	  ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv \
	  ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/dual-issue-core-slice.sv

dual-slice-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_slice_tb --top-module tb_dual_issue_core_slice -o tb_dual_issue_core_slice \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv \
	  ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv \
	  ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/dual-issue-core-slice.sv tb-dual-issue-core-slice.sv
	./obj_dir/dual_slice_tb/tb_dual_issue_core_slice

dual-alu-core-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_alu_core ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/dual-issue-core-slice.sv ../rtl/cpu/dual_issue/dual-issue-alu-core.sv

dual-alu-core-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_alu_core_tb --top-module tb_dual_issue_alu_core -o tb_dual_issue_alu_core ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/dual_issue/issue-scoreboard.sv ../rtl/cpu/dual_issue/dual-issue-alu.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-decode-execute.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/dual-issue-core-slice.sv ../rtl/cpu/dual_issue/dual-issue-alu-core.sv tb-dual-issue-alu-core.sv
	./obj_dir/dual_alu_core_tb/tb_dual_issue_alu_core

dual-rv32i-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module dual_issue_rv32i_core ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-rv32i-core.sv

dual-rv32i-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/dual_rv32i_tb --top-module tb_dual_issue_rv32i_core -o tb_dual_issue_rv32i_core ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/interconnect/interfaces/mem-if.sv ../rtl/memory/sync-memory.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-rv32i-core.sv tb-dual-issue-rv32i-core.sv
	./obj_dir/dual_rv32i_tb/tb_dual_issue_rv32i_core

dual-multicore-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module multicore_cpu_dual_issue ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-cache.sv ../rtl/cache/l2-cache.sv ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-rv32i-core.sv ../rtl/soc/variants/multicore-dual-issue.sv

dual-multicore-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/multicore_dual_issue_tb --top-module tb_multicore_dual_issue -o tb_multicore_dual_issue ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-cache.sv ../rtl/cache/l2-cache.sv ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/cpu/dual_issue/dual-fetch-pair.sv ../rtl/cpu/dual_issue/register-file-2wide.sv ../rtl/cpu/dual_issue/dual-issue-rv32i-core.sv ../rtl/soc/variants/multicore-dual-issue.sv tb-multicore-dual-issue.sv
	./obj_dir/multicore_dual_issue_tb/tb_multicore_dual_issue

issue-scoreboard-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_issue_scoreboard -o tb_issue_scoreboard ../rtl/cpu/dual_issue/issue-scoreboard.sv tb-issue-scoreboard.sv
	./obj_dir/tb_issue_scoreboard

wb-msi-cache-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/wb_msi_cache_tb --top-module tb_wb_msi_cache -o tb_wb_msi_cache ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/interconnect/coherence/msi-coherence-hub.sv ../rtl/cache/wb-msi-cache.sv tb-wb-msi-cache.sv
	./obj_dir/wb_msi_cache_tb/tb_wb_msi_cache

multicore-wb-msi-test: test-basic.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_multicore_wb_msi -o tb_multicore_wb_msi \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/interconnect/coherence/msi-coherence-hub.sv ../rtl/interconnect/interfaces/coherence-if.sv \
	  ../rtl/cache/l1i-cache.sv ../rtl/cache/wb-msi-cache.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/interconnect/noc/noc-fabric.sv \
	  ../rtl/cpu/core/single-core.sv ../rtl/soc/variants/multicore-wb-msi.sv ../rtl/memory/sync-memory.sv tb-multicore-wb-msi.sv
	./obj_dir/tb_multicore_wb_msi +PROG=$(PROG).hex

regress: lint bus-lint l1i-lint l1d-lint l2-lint multicore-lint axi-multicore-lint nb-lint wb-msi-lint \
         gpu-axi-lint gpu-axi-test gpu-engine-lint gpu-engine-test primitive-gpu-lint primitive-gpu-test mshr-lint mshr-test l1d-nb-test wb-msi-cache-test dual-issue-test dual-decode-lint dual-decode-test dual-fetch-test regfile-2wide-test dual-slice-lint dual-slice-test dual-alu-core-lint dual-alu-core-test dual-rv32i-lint dual-rv32i-test dual-multicore-lint dual-multicore-test bus-test l1i-test l1d-test coherence-test noc-test \
         multicore-test multicore-wb-msi-test issue-scoreboard-test interrupt-test \
         dram-test axi-lite-test run

dram-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps -Wno-fatal -Wno-UNSIGNED --top-module tb_dram -o tb_dram ../rtl/interconnect/interfaces/mem-if.sv ../rtl/memory/dram-model.sv tb-dram.sv
	./obj_dir/tb_dram

axi-lite-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps -Wno-fatal --top-module tb_axi_lite -o tb_axi_lite ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/axi4-lite-if.sv ../rtl/interconnect/bridges/mem-to-axi-lite.sv tb-axi-lite.sv
	./obj_dir/tb_axi_lite

interrupt-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_interrupt -o tb_interrupt \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/cpu/core/single-core.sv ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/memory/sync-memory.sv tb-interrupt.sv
	./obj_dir/tb_interrupt

multicore-test: $(PROG).hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --top-module tb_multicore -o tb_multicore \
	  ../rtl/cpu/core/rv32i-pkg.sv ../rtl/cpu/core/alu.sv ../rtl/cpu/core/register-file.sv ../rtl/cpu/core/imm-gen.sv ../rtl/cpu/core/branch-unit.sv ../rtl/cpu/core/control-unit.sv ../rtl/cpu/core/program-counter.sv \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/interconnect/interfaces/msi-coherence-if.sv ../rtl/cache/l1i-cache.sv ../rtl/cache/l1d-cache.sv ../rtl/cache/wb-msi-cache.sv \
	  ../rtl/cache/l2-cache.sv ../rtl/interconnect/coherence/coherence-hub.sv ../rtl/interconnect/coherence/msi-coherence-hub.sv \
	  ../rtl/interconnect/noc/shared-interconnect.sv ../rtl/memory/sync-memory.sv ../rtl/cpu/core/single-core.sv ../rtl/soc/variants/multicore-single-issue.sv tb-multicore.sv
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
	  ../rtl/interconnect/interfaces/coherence-if.sv ../rtl/interconnect/coherence/coherence-hub.sv \
	  ../dv/tb-coherence-uvm.sv
	./obj_dir/tb_coherence_uvm

# Canonical SoC + HW benchmarks (dual-issue, WB-MSI, L2, NoC, banked DRAM, GPU).
soc-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module soc $(SOC_SRCS)

axi-bridge-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module axi4_to_mem \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/interconnect/interfaces/axi4-if.sv \
	  ../rtl/interconnect/bridges/axi4-to-mem.sv
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps --top-module banked_dram \
	  ../rtl/interconnect/interfaces/mem-if.sv ../rtl/memory/banked-dram.sv

banked-dram-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps -Wno-fatal --top-module tb_dram -o tb_dram_banked ../rtl/interconnect/interfaces/mem-if.sv ../rtl/memory/banked-dram.sv tb-dram.sv
	./obj_dir/tb_dram_banked

soc-test: test-basic.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/soc_tb --top-module tb_soc -o tb_soc $(SOC_SRCS) tb-soc.sv
	./obj_dir/soc_tb/tb_soc +PROG=$(PROG).hex

bench-ilp: bench-ilp.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/soc_tb --top-module tb_soc -o tb_soc $(SOC_SRCS) tb-soc.sv
	./obj_dir/soc_tb/tb_soc +PROG=bench-ilp.hex

bench-dcache: bench-dcache-stream.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/soc_tb --top-module tb_soc -o tb_soc $(SOC_SRCS) tb-soc.sv
	./obj_dir/soc_tb/tb_soc +PROG=bench-dcache-stream.hex

bench-gpu: bench-gpu-fill.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/soc_tb --top-module tb_soc -o tb_soc $(SOC_SRCS) tb-soc.sv
	./obj_dir/soc_tb/tb_soc +PROG=bench-gpu-fill.hex

bench-all: bench-ilp.hex bench-dcache-stream.hex bench-gpu-fill.hex
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps --Mdir obj_dir/soc_tb --top-module tb_soc -o tb_soc $(SOC_SRCS) tb-soc.sv
	./obj_dir/soc_tb/tb_soc +PROG=bench-ilp.hex
	./obj_dir/soc_tb/tb_soc +PROG=bench-dcache-stream.hex
	./obj_dir/soc_tb/tb_soc +PROG=bench-gpu-fill.hex

clean:
	rm -rf obj_dir *.hex *.vcd
