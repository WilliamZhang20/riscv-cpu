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
        $(RTL_DIR)/single-core.sv \
        tb-core.sv

TOP   := tb_core
BIN   := obj_dir/$(TOP)
PROG  ?= test-basic
FLAGS := --binary --timing --assert --timescale 1ns/1ps -Wno-DECLFILENAME

.PHONY: all run trace waves lint bus-lint bus-test clean
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
	  $(filter-out tb-core.sv,$(SRCS))

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

clean:
	rm -rf obj_dir *.hex *.vcd
