# Using Verilator

## Quick start

```sh
cd sim
make            # assemble test-basic.s, build the DUT, run the testbench
make regress    # lint and run all block/integration tests
make l1i-test   # adversarial standalone L1 instruction-cache test
make l1d-test   # data-cache policy, subword, and failure-atomicity test
make coherence-test # two private L1Ds, invalidation, concurrent stores
make multicore-lint # lint the complete N-core composition root
make trace      # same, plus one line per retired instruction
make lint       # Verilator lint of the RTL only
make clean
```

`make` prints `tb_core: PASS` on success and exits non-zero via `$fatal` on any
failure. The Makefile sets `PATH`/`VERILATOR_ROOT` explicitly rather than
relying on `~/.bashrc`, because make recipes run in non-interactive shells that
never read it.

## What's here

| File | Purpose |
|---|---|
| `Makefile` | build + run; `rv32i-pkg.sv` must be first in the source list |
| `tb-core.sv` | self-checking core + split L1 caches + interconnect test |
| `cache/tb-l1i-cache.sv` | standalone cache refill/backpressure/error test |
| `cache/tb-l1d-cache.sv` | standalone load/store policy and atomicity test |
| `cache/tb-coherence.sv` | two-cache visibility and store-serialization test |
| `asm.py` | minimal two-pass RV32I assembler (no toolchain on this machine) |
| `test-basic.s` | self-checking smoke test |

## Testbench contract

Programs signal their result by writing a magic word to `0x500` and executing
`ebreak`:

- `0x600DC0DE` — pass
- `0xBAADC0DE` — fail

`tb-core.sv` also fails the run on a timeout, an illegal instruction, an
out-of-range access, or a misaligned fetch or data access. Plusargs:
`+PROG=<file.hex>`, `+TRACE`, `+MAXCYC=<n>`.

## Memory model

The integration test uses a flat 4 KiB synchronous, byte-enabled memory behind
the shared request/response interconnect. Programs load at `0x000`; the data
region starts at `0x400`. Instructions pass through a blocking 1 KiB L1I; data
passes through a 1 KiB write-through/no-write-allocate L1D. Both use 16-byte
lines and feed a shared 16 KiB L2. Addresses above `0x7fff_ffff` bypass caching
for MMIO. The memory target reports misaligned and out-of-range accesses through
the bus response.

## Writing a test

`asm.py` covers RV32I plus `nop`, `j`, `mv`, `fence`, `ecall`, `ebreak`, ABI
register names, and labels. It is not a general assembler — no relocations, no
sections, no `%hi`/`%lo`.

Two structural rules the smoke test follows, both learned from mutation testing:

- **Put `fail:` before `pass:`.** Falling off the end of the test body must land
  on the fail path. Otherwise a core in which no branch or jump is ever taken
  reaches `pass` by fall-through and the test reports success.
- **Include at least one backward branch.** A program with only forward branches
  never sets B-type `imm[11]`, so a decoder that drops that bit still passes.

```sh
make PROG=my-test      # builds my-test.hex from my-test.s and runs it
```
