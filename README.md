# RISCV 32-Bit Multi-Core CPU

Goal: develop a multi-core CPU + iGPU from scratch in SystemVerilog and simulate it on a PDK

Will use RV32I ISA, everything coded in SystemVerilog

## Todo list

- [x] Baseline multicycle core (5-state FSM, one instruction in flight)
- [x] Single CPU pipelined 5-stage core (IF, ID, EX, MEM, WB)
- [x] Backpressured memory interconnect
- [x] Blocking 2-way set-associative L1 instruction cache
- [x] Write-through 2-way set-associative L1 data cache
- [x] Shared L2 cache and broadcast-invalidation coherence
- [x] Parameterized multicore CPU subsystem top
- [x] Transaction-level NoC fabric (address routing, arbitration, backpressure)
- [x] Phase 1 baseline instrumentation and regression coverage
- [x] Phase 2: improve L1 capacity/associativity and quantify the gain
- [~] Phase 3: tagged transactions and nonblocking read-mostly L1/MSHR path
- [~] Phase 4: write-back L1 and MSI coherence composition root
- [~] Phase 5: connected 2-wide in-order issue slice and full RV32I composition root
- [ ] Phase 6: renamed out-of-order backend and reorder buffer
- [ ] Implement Pipeline Interrupts
- [ ] Implement an integrated GPU
- [ ] Connect the CPU and GPU
- [ ] Engineer a "mouse and keyboard" interface

## Status

`rtl/` holds a working five-stage pipelined RV32I core with forwarding, branch
flushes, and memory backpressure. Separate instruction and data request/response
ports feed a round-robin shared interconnect and synchronous memory. The
instruction path includes a 1 KiB 2-way set-associative, blocking L1 cache with
16-byte lines and sequential 32-bit refills. The matching 1 KiB L1 data cache uses
read-allocate, write-through, and no-write-allocate policies; cached stores are
committed only after memory acknowledges them. A shared 16 KiB L2 sits below
the L1 interconnect. Cacheable address parameters provide uncached/MMIO bypass,
and a separate coherence hub serializes write ownership and broadcasts line
invalidations between private L1Ds.

The transaction-level NoC is intentionally implemented as the parameterized
`shared_interconnect` behind `rtl/bus/noc-fabric.sv`. It provides independent
per-target round-robin arbitration, address-map error responses, one-outstanding
response ownership, and stable backpressure behavior. A flit-based mesh is not
part of this CPU milestone; it would add complexity without a traffic workload
to exercise it.

Phase 1 exposes observational counters from each `cpu_core` through
`multicore_cpu`: `cycle_count`, `retired_count`, `imem_stall_count`, and
`dmem_stall_count`. They establish a CPI/stall baseline without changing
pipeline or memory behavior. Later phases should be evaluated against these
counters.

```sh
cd sim && make          # -> tb_core: PASS
cd sim && make regress  # lint + block tests + integration test
```

There is no RISC-V toolchain on this machine, so `sim/asm.py` is a minimal
assembler that turns `sim/*.s` into `$readmemh` images. See `sim/README.md`.

The AXI integration points are `rtl/multicore-axi-lite.sv` and
`rtl/bus/axi4-if.sv`. The former wraps the complete legacy multicore subsystem
for FPGA BRAM, SoC interconnect, or AXI GPIO/UART/timer windows. The latter is
the burst-capable interface used by `rtl/gpu/axi4-read-master.sv` and `rtl/gpu/axi4-gpu-engine.sv`: a useful
starting point for an iGPU scanout/raster engine to fetch framebuffer,
texture, or command-stream data. The GPU engine exposes base address at 0x04, beat count at 0x08, start at 0x00, and status at 0x0c. Keep AXI4-Lite for control/status registers;
use full AXI4 for high-bandwidth GPU traffic and future cache refills.

Phase 3 now has `tagged_mem_if`, compatibility bridges, `mshr_table`, and an
MSHR-capable read-mostly L1 in `rtl/cache/l1d-nb-cache.sv`, composed by
`rtl/multicore-nb.sv`. Phase 4 has data-carrying MSI channels, a serialized
coherence hub, and a write-back L1 in `rtl/cache/wb-msi-cache.sv`, composed by
`rtl/multicore-wb-msi.sv`; its smoke test is `multicore-wb-msi-test`. Phase 5
has a verified scoreboard in `rtl/core/issue-scoreboard.sv`, a two-lane integer execution shell in `rtl/core/dual-issue-alu.sv`, a decoder-facing ALU wrapper in `rtl/core/dual-issue-decode-execute.sv`, a backpressure-safe dual-fetch pair in `rtl/core/dual-fetch-pair.sv`, and a four-read/two-write register file in `rtl/core/register-file-2wide.sv`, all connected by the `rtl/core/dual-issue-core-slice.sv` composition root, with the runnable ALU-only fetch/retirement root in `rtl/core/dual-issue-alu-core.sv` and the full RV32I memory/branch/CSR composition root in `rtl/core/dual-issue-rv32i-core.sv`. The full root issues and commits two independent instructions when legal, serializes memory operations through its data port, handles same-pair RAW dependencies, and redirects on control flow. It is composed into `rtl/multicore-dual-issue.sv` for cache/L2/coherence/memory integration, while the legacy multicore `cpu_core` remains available as the comparison baseline. These are deliberately
parallel composition roots so the legacy regression remains a comparison
baseline while each phase is integrated into the core pipeline.

The new protocol blocks include simulation-time assertions for unique MSHR
IDs, no MSI grant while snoops are pending, and legal two-wide issue ordering.
Yosys/SymbiYosys are not installed in this environment, so these assertions
are linted and exercised under Verilator rather than fully proven yet.

## Toolchain

### Verilator

Verilator 5.050 is built from source at `~/.local/verilator-5.050` (~125 MB).
There is no Lmod module for it on Trillium (`module spider verilator` finds
nothing), so a source build is the only option. All build dependencies
(autoconf, flex, bison, help2man, ccache, g++ 12, libfl) and `z3` — which backs
constrained randomization — already come from the CVMFS stack.

`~/.bashrc` sets:

```sh
export VERILATOR_ROOT=$HOME/.local/verilator-5.050/share/verilator
export PATH=$HOME/.local/verilator-5.050/bin:$PATH
export MANPATH=$HOME/.local/verilator-5.050/share/man:$MANPATH
```

(Pre-install backup: `~/.bashrc.bak-verilator`.)

#### When PATH needs refreshing

`~/.bashrc` is only read by **interactive** shells. That is the whole rule; the
cases below follow from it.

| Situation | On PATH? | What to do |
|---|---|---|
| New login / new terminal | yes | nothing |
| Shell opened *before* the install | **no** | `source ~/.bashrc` |
| Interactive subshell (`bash`, `bash -i`) | yes | nothing |
| Login subshell (`bash -l`) | yes | nothing |
| `bash script.sh`, `./script.sh`, `bash -c` | **no** | see below |
| Makefile recipes, cron | **no** | see below |
| After `module purge` / `module load` | yes | nothing — Lmod does not manage this entry |

The one that actually bites: a script with a plain `#!/bin/bash` shebang is
non-interactive and non-login, so it never reads `~/.bashrc` and `verilator`
will not be found. Pick one of:

```sh
#!/bin/bash -l                                   # login shell, reads .bashrc
source ~/.bashrc                                 # explicit, at top of script
export PATH=$HOME/.local/verilator-5.050/bin:$PATH   # explicit, most reproducible
```

**SLURM batch jobs** inherit the submitting shell's environment by default
(`--export=ALL`), so PATH normally carries into the job. That breaks under
`--export=NONE`. Set PATH explicitly in job scripts rather than relying on
inheritance.

#### Usage

```sh
# self-contained SV testbench with initial blocks
verilator --binary --timing --assert --top-module tb  pkg.sv dut.sv tb.sv

# C++ harness driving the DUT
verilator --cc --exe --build --assert --timing --top-module top \
          pkg.sv dut.sv main.cpp
```

- `--assert` is required for `assert property` / SVA; assertions are silently
  ignored without it.
- Verilator promotes lint warnings to errors by default. `-Wno-fatal` downgrades
  them while iterating.
- SVA samples in the preponed region (before the clock edge), but a C++ harness
  reading a signal after `eval()` sees the post-edge value. A 4-deep pipeline is
  therefore `##4` in an assertion but 3 iterations in the C++ loop.

Verified working: packages, packed structs, enums and casts, interfaces with
modports, `always_ff`/`always_comb`, SVA with `disable iff`, classes with
inheritance and `virtual` methods, constrained `randomize()`, queues, dynamic
and associative arrays.
