# Store-reuse cache benchmark: 16 passes over a 1 KiB working set.
# Write-through must send every store below L1; write-back should retain dirty
# lines after the first pass.  The standard testbench checks the pass marker.
start:
    addi x20, x0, 16
outer:
    addi x1, x0, 0x400
    addi x2, x0, 0x800
    addi x3, x20, 0
inner:
    sw   x3, 0(x1)
    addi x1, x1, 4
    bne  x1, x2, inner
    addi x20, x20, -1
    bne  x20, x0, outer
    addi x4, x0, 0x500
    lui  x5, 0x600dc
    addi x5, x5, 0x0de
    sw   x5, 0(x4)
    ebreak
fail:
    addi x4, x0, 0x500
    lui  x5, 0xbaadc
    addi x5, x5, 0x0de
