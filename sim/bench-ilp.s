# bench-ilp.s -- dual-issue ALU throughput microbenchmark.
#
# 32 iterations x 4 independent ADDs per iteration. A 2-wide in-order core
# can co-issue the independent adds; IPC should approach ~1.5-2.0 on the
# canonical dual-issue SoC. Ends with the standard pass marker at 0x500.
start:
    addi x20, x0, 32
    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 3
    addi x4, x0, 4
loop:
    add x5, x1, x2
    add x6, x3, x4
    add x7, x1, x3
    add x8, x2, x4
    add x9, x5, x6
    add x10, x7, x8
    add x11, x9, x10
    add x12, x11, x5
    addi x20, x20, -1
    bne x20, x0, loop
    # checksum must be nonzero deterministic: 32 iters, just check x12 != 0
    beq x12, x0, fail
    j pass

fail:
    addi x24, x0, 0x400
    lui x1, 0xBAADC
    addi x1, x1, 0x0DE
    sw x1, 0x100(x24)
    ebreak

pass:
    addi x24, x0, 0x400
    lui x1, 0x600DC
    addi x1, x1, 0x0DE
    sw x1, 0x100(x24)
    ebreak
