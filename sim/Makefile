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
        $(RTL_DIR)/l1i-cache.sv \
        $(RTL_DIR)/l1d-cache.sv \
        $(RTL_DIR)/bus/shared-interconnect.sv \
        $(RTL_DIR)/memory/sync-memory.sv \
        $(RTL_DIR)/single-core.sv \
        tb-core.sv

TOP   := tb_core
BIN   := obj_dir/$(TOP)
PROG  ?= test-basic
FLAGS := --binary --timing --assert --timescale 1ns/1ps -Wno-DECLFILENAME

.PHONY: all run trace waves lint bus-lint bus-test bus-core-lint bus-core-test \
        l1i-lint l1i-test l1d-lint l1d-test regress clean
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
            ../rtl/memory/sync-memory.sv \
            bus/tb-shared-interconnect.sv

bus-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_shared_interconnect -o tb_shared_interconnect $(BUS_SRCS)
	./obj_dir/tb_shared_interconnect

bus-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module shared_interconnect \
	  ../rtl/bus/mem-if.sv \
	  ../rtl/bus/shared-interconnect.sv \
	  ../rtl/memory/sync-memory.sv

BUS_CORE_SRCS := ../rtl/rv32i-pkg.sv \
                 ../rtl/alu.sv \
                 ../rtl/register-file.sv \
                 ../rtl/imm-gen.sv \
                 ../rtl/branch-unit.sv \
                 ../rtl/control-unit.sv \
                 ../rtl/bus/mem-if.sv \
                 ../rtl/bus/shared-interconnect.sv \
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
            ../rtl/l1d-cache.sv \
            cache/tb-l1d-cache.sv

l1d-lint:
	$(VERILATOR) --lint-only --assert --timescale 1ns/1ps \
	  --top-module l1d_cache ../rtl/bus/mem-if.sv ../rtl/l1d-cache.sv

l1d-test:
	$(VERILATOR) --binary --timing --assert --timescale 1ns/1ps \
	  --top-module tb_l1d_cache -o tb_l1d_cache $(L1D_SRCS)
	./obj_dir/tb_l1d_cache

regress: lint bus-lint l1i-lint l1d-lint bus-test l1i-test l1d-test run

clean:
	rm -rf obj_dir *.hex *.vcd
