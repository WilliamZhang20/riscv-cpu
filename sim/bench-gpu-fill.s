# bench-gpu-fill.s -- GPU AXI-burst fill microbenchmark (CPU-driven).
#
# Programs a 4x2 solid rect at FB base 0x1000 via the MMIO window at
# 0x8000_0000, polls status.done, verifies two framebuffer pixels, then the
# standard pass marker at 0x500. Exercises: MMIO router, AXI4-Lite ctrl,
# AXI4 burst writes through axi4_to_mem into banked DRAM.
#
# Reg map: 00 cmd, 04 base, 08 stride, 0c prim(0=rect), 10 v0, 14 v1, 1c color, 20 status.
start:
    lui x10, 0x80000          # x10 = GPU_BASE 0x8000_0000
    lui x11, 0x1              # x11 = FB base 0x1000
    sw x11, 4(x10)            # base
    addi x12, x0, 16
    sw x12, 8(x10)            # stride = 16 bytes
    sw x0, 12(x10)            # primitive_type = rectangle
    sw x0, 16(x10)            # v0 x=0, y=0
    lui x13, 0x20
    addi x13, x13, 4          # v1 x=4, y=2 -> 4x2 rect
    sw x13, 20(x10)
    addi x14, x0, 0x7F
    sw x14, 28(x10)           # color = 0x7F
    addi x15, x0, 1
    sw x15, 0(x10)            # start
poll:
    lw x16, 32(x10)           # status @ 0x20
    andi x17, x16, 2
    beq x17, x0, poll
    andi x17, x16, 4
    bne x17, x0, fail         # error bit
    lw x18, 0(x11)            # FB[0][0]
    bne x18, x14, fail
    addi x19, x11, 20         # last pixel of 4x2 @ stride 16: row1+col3 = 16+12=28? check row0 col3 = 12
    lw x19, 12(x11)           # row0 last pixel
    bne x19, x14, fail
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
