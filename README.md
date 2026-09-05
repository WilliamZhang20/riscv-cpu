# RISCV 32-Bit Multi-Core CPU

Goal: develop a multi-core CPU + iGPU from scratch in SystemVerilog and simulate it on a PDK

Will use RV32I ISA, everything coded in SystemVerilog

## Todo list

- [x] Baseline multicycle core (5-state FSM, one instruction in flight)
- [x] Single CPU pipelined 5-stage core (IF, ID, EX, MEM, WB)
- [x] Backpressured memory interconnect
- [x] Blocking direct-mapped L1 instruction cache
- [x] Write-through direct-mapped L1 data cache
- [ ] Shared L2 cache and coherence
- [ ] Implement Pipeline Interrupts
- [ ] Implement an integrated GPU
- [ ] Connect the CPU and GPU
- [ ] Engineer a "mouse and keyboard" interface

## Status

`rtl/` holds a working five-stage pipelined RV32I core with forwarding, branch
flushes, and memory backpressure. Separate instruction and data request/response
ports feed a round-robin shared interconnect and synchronous memory. The
instruction path includes a 1 KiB direct-mapped, blocking L1 cache with 16-byte
lines and sequential 32-bit refills. The matching 1 KiB L1 data cache uses
read-allocate, write-through, and no-write-allocate policies; cached stores are
committed only after memory acknowledges them.

```sh
cd sim && make          # -> tb_core: PASS
cd sim && make regress  # lint + block tests + integration test
```

There is no RISC-V toolchain on this machine, so `sim/asm.py` is a minimal
assembler that turns `sim/*.s` into `$readmemh` images. See `sim/README.md`.

Not implemented yet: a shared L2, coherence/multicore, complete traps/CSRs, and
the GPU. `l2-cache.sv` is still empty.

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
