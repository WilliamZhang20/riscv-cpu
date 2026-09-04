# UVM in Verilator

## Status: it works, but it is not the right next step

Verified on 2026-09-03 with Verilator 5.050 and Accellera UVM 2020.3.1
(`github.com/accellera-official/uvm-core`), running a full agent against
`rtl/single-core.sv`:

```
UVM_INFO @ 0: reporter [RNTST] Running test core_test...
UVM_INFO [TEST] core halted; driver consumed 12 items
UVM_INFO [SB]   scoreboard saw 161 retires, last pc=00000244
UVM_ERROR :    0
```

161 retires matches `sim/tb-core.sv` exactly. Everything that typically breaks
UVM on a new simulator was exercised and worked:

- virtual interface handed over through `uvm_config_db#(virtual core_if)`
- `type_id::create` factory construction
- `uvm_analysis_port` / `uvm_analysis_imp` (monitor to scoreboard)
- sequencer/driver `get_next_item` / `item_done` handshake
- `uvm_sequence` with constrained `randomize()` (z3-backed)
- build/connect/run/report phases with objections
- `uvm_field_int` macros and `uvm_info` / `uvm_error` reporting

Nothing here is blocked on tooling. The reason `dv/` is still empty is
methodology fit, not capability — see "Why not yet" below.

## The recipe (three non-obvious steps)

```sh
git clone --depth 1 https://github.com/accellera-official/uvm-core.git
cp -r uvm-core/src/dpi dpi          # patched copy, see step 2

verilator --binary --timing --vpi --top-module tb \
          --build-jobs $(nproc) --verilate-jobs $(nproc) \
          -CFLAGS "-I$PWD/dpi" \
          +incdir+uvm-core/src uvm-core/src/uvm_pkg.sv dpi/uvm_dpi.cc tb.sv
```

1. **`uvm_dpi.cc` must be passed as a source.** Without it the link fails on
   `uvm_re_*`, `uvm_hdl_*` and `uvm_dpi_get_*`.
2. **UVM has no Verilator HDL backend.** `src/dpi/uvm_hdl.c` selects among
   VCS, Questa and Xcelium and otherwise hits
   `#error "hdl vendor backend is missing"`. Replace that `#error` with an
   include of a stub providing `uvm_hdl_check_path/read/deposit/force/release/
   release_and_read/force_time`. **Consequence: backdoor register access is a
   no-op, so the UVM register layer (RAL) frontdoor works but backdoor does
   not.** A real backend would have to be written against Verilator's VPI.
3. **`--vpi` is required.** `uvm_svcmd_dpi.c` calls `vpi_get_vlog_info` and
   friends; without the flag the link fails on the VPI symbols.

## What it costs

| | core + `sim/tb-core.sv` | + UVM |
|---|---|---|
| generated C++ files | 6 | ~2900 |
| peak verilate RSS | 32 MB | 1.24 GB |
| build, 16 jobs, warm ccache | < 1 s | ~55 s |
| build, cold | ~11 s | minutes |

That is roughly a 100x hit on the edit-build-run loop — the loop that matters
most during RTL bring-up.

## Why not yet

UVM buys reusable verification IP across teams, blocks and projects:
standardized component structure, factory overrides, config DB, sequence
libraries, RAL. Those pay off with several engineers, several blocks sharing
protocols, and a long project life. This is one person, one core, and the
"stimulus" is instruction streams rather than protocol transactions.

What actually finds bugs in a CPU, in descending value:

1. **Co-simulation against a golden ISS.** Run the core and Spike (or
   Sail-RISCV) on the same program, compare architectural state after every
   retired instruction. This is the backbone of RISC-V verification and it is a
   C++ harness, not a methodology.
2. **ISA compliance suites.** riscv-tests, then RISCOF / riscv-arch-test.
   Directed and self-checking — the same shape as `sim/test-basic.s`.
3. **Formal.** riscv-formal (Yosys + SymbiYosys) proves ISA conformance of the
   pipeline rather than sampling it. For a core this size it is very high value
   per hour and needs no UVM. Neither yosys nor sby is installed yet.
4. **Random instruction generation.** riscv-dv is the standard. Its generator is
   UVM-based, but it ships a `pyflow` mode that is pure Python and needs no UVM
   at all.
5. **SVA on pipeline invariants.** Already supported — `--assert` is on in
   `sim/Makefile`.

Note that mutation testing found three real holes in `sim/test-basic.s` (see
`sim/README.md`). None of them would have been found by adding methodology; they
were found by attacking the tests. That is where the next verification hour
should go.

## When to turn UVM on

When the work becomes genuinely protocol-shaped and reusable:

- the cache hierarchy and interconnect, where coherence agents are worth reusing
  across L1/L2 and across cores
- the CPU-GPU interface

Both are items further down the top-level todo list. Revisit then.

If the goal is instead to *learn UVM* as a marketable skill, that is a fine
reason — but do it on a small dedicated block (a FIFO, an APB slave), not on
this core, so a methodology bug and an RTL bug are never confused. **pyuvm** on
cocotb is also worth considering: real UVM semantics, Python tooling, no
1.2 GB elaborations.
