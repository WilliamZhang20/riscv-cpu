# bench-dcache-stream.s -- L1/L2/DRAM streaming microbenchmark.
#
# 4 passes over 256 words (1 KiB) at 0x400: store sequence, reload and
# accumulate checksum. First pass cold (DRAM latency), later passes L1 hits
# under write-back MSI. Verifies checksum, then pass marker at 0x500.
start:
    addi x20, x0, 4
    addi x21, x0, 0
outer:
    addi x1, x0, 0x400
    lui x2, 0x1
    addi x2, x2, 0x0       # x2 = 0x1000 (end = 0x400 + 1024)
    addi x2, x1, 1024
    add x3, x0, x20
inner_store:
    sw x3, 0(x1)
    addi x1, x1, 4
    bne x1, x2, inner_store
    # reload + checksum
    addi x1, x0, 0x400
inner_load:
    lw x4, 0(x1)
    add x21, x21, x4
    addi x1, x1, 4
    bne x1, x2, inner_load
    addi x20, x20, -1
    bne x20, x0, outer
    # expected checksum: 256 words * (4+3+2+1) = 2560
    lui x5, 0x1
    addi x5, x5, -1536        # 4096 - 1536 = 2560
    bne x21, x5, fail
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
