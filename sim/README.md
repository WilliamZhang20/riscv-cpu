# Using Verilator

## Quick start

```sh
cd sim
make            # assemble test-basic.s, build the DUT, run the testbench
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
| `tb-core.sv` | self-checking testbench and flat 4 KiB memory model |
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

One flat von Neumann array, 1024 words covering `0x000`–`0xFFF`: asynchronous
read on both ports, byte-enabled synchronous write, no latency and no
handshake. Programs load at `0x000`, the data region starts at `0x400`.

This is deliberately "magic" memory. It validates the datapath without a memory
system in the way; because it is indexed by word it would silently absorb a
misaligned access, which is why the testbench checks alignment on the bus
instead.

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
