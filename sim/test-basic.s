# ============================================================================
# test-basic.s -- self-checking RV32I smoke test for the baseline core.
#
# Every check branches to `fail` on mismatch. The program ends in EBREAK with
# a magic word at 0x500:  0x600DC0DE = pass, 0xBAADC0DE = fail.
#
# Data region base is 0x400.
# ============================================================================

start:
    # ---- LUI + ADDI ------------------------------------------------------
    lui   x1, 0x12345
    addi  x1, x1, 0x678            # x1 = 0x12345678
    lui   x2, 0x12345
    addi  x2, x2, 0x678
    bne   x1, x2, fail

    # ---- ADD / SUB -------------------------------------------------------
    addi  x3, x0, 100
    addi  x4, x0, -30
    add   x5, x3, x4               # 70
    addi  x6, x0, 70
    bne   x5, x6, fail

    sub   x7, x3, x4               # 130
    addi  x8, x0, 130
    bne   x7, x8, fail

    # ---- AND / OR / XOR   (100 = 0x64, -30 = 0xFFFFFFE2) -----------------
    and   x9, x3, x4               # 0x60 = 96
    addi  x10, x0, 96
    bne   x9, x10, fail

    or    x9, x3, x4               # 0xFFFFFFE6 = -26
    addi  x10, x0, -26
    bne   x9, x10, fail

    xor   x9, x3, x4               # 0xFFFFFF86 = -122
    addi  x10, x0, -122
    bne   x9, x10, fail

    # ---- SLT / SLTU / SLTI / SLTIU ---------------------------------------
    addi  x12, x0, 1
    slt   x11, x4, x3              # -30 <s 100 -> 1
    bne   x11, x12, fail
    sltu  x11, x4, x3              # 0xFFFFFFE2 <u 100 -> 0
    bne   x11, x0, fail
    slti  x11, x4, 0               # -30 <s 0 -> 1
    bne   x11, x12, fail
    sltiu x11, x4, -1              # 0xFFFFFFE2 <u 0xFFFFFFFF -> 1
    bne   x11, x12, fail

    # ---- immediate shifts -------------------------------------------------
    addi  x13, x0, 1
    slli  x13, x13, 20             # 0x00100000
    lui   x14, 0x100
    bne   x13, x14, fail

    srli  x15, x13, 8              # 0x00001000
    lui   x16, 0x1
    bne   x15, x16, fail

    addi  x17, x0, -256
    srai  x18, x17, 4              # -16  (sign-extending)
    addi  x19, x0, -16
    bne   x18, x19, fail

    srli  x18, x17, 4              # 0x0FFFFFF0 (zero-filling)
    lui   x19, 0x10000
    addi  x19, x19, -16
    bne   x18, x19, fail

    # ---- register shifts --------------------------------------------------
    addi  x20, x0, 4
    sll   x21, x3, x20             # 100 << 4 = 1600
    addi  x22, x0, 1600
    bne   x21, x22, fail
    srl   x21, x22, x20            # back to 100
    bne   x21, x3, fail
    sra   x21, x17, x20            # -256 >> 4 = -16
    addi  x23, x0, -16
    bne   x21, x23, fail

    # ---- x0 is hardwired to zero -----------------------------------------
    addi  x0, x0, 99               # must be discarded
    addi  x12, x0, 5
    addi  x13, x0, 5
    bne   x12, x13, fail

    # ---- word load / store -----------------------------------------------
    addi  x24, x0, 0x400
    sw    x1, 0(x24)
    lw    x25, 0(x24)
    bne   x25, x1, fail

    # ---- byte load / store, both sign and lane -----------------------------
    addi  x26, x0, -1
    sb    x26, 4(x24)              # 0xFF into byte lane 0 of 0x404
    lb    x27, 4(x24)              # -1
    bne   x27, x26, fail
    addi  x28, x0, 255
    lbu   x27, 4(x24)              # 255
    bne   x27, x28, fail

    addi  x26, x0, 0x5A
    sb    x26, 7(x24)              # byte lane 3 of the same word
    lbu   x27, 7(x24)
    bne   x27, x26, fail
    lbu   x27, 4(x24)              # lane 0 must be untouched
    bne   x27, x28, fail

    # ---- halfword load / store --------------------------------------------
    addi  x26, x0, -1234           # 0xFFFFFB2E
    sh    x26, 8(x24)
    lh    x27, 8(x24)              # -1234
    bne   x27, x26, fail
    lui   x28, 0x10
    addi  x28, x28, -1234          # 64302 = 0xFB2E
    lhu   x27, 8(x24)
    bne   x27, x28, fail

    addi  x26, x0, 0x123
    sh    x26, 10(x24)             # upper half of the same word
    lhu   x27, 10(x24)
    bne   x27, x26, fail
    lhu   x27, 8(x24)              # lower half must be untouched
    bne   x27, x28, fail

    # ---- AUIPC + JALR ------------------------------------------------------
    auipc x5, 0                    # x5 = A
    addi  x5, x5, 16               # x5 = A+16 = after_jalr
    jalr  x6, 0(x5)                # link = A+12
    j     fail
after_jalr:
    auipc x7, 0                    # A+16
    addi  x7, x7, -4               # A+12
    bne   x6, x7, fail

    # ---- JALR must clear bit 0 of the computed target ----------------------
    auipc x5, 0                    # B
    addi  x5, x5, 17               # B+17, deliberately odd
    jalr  x0, 0(x5)                # must land on B+16, not B+17
    j     fail
after_jalr2:

    # ---- JAL ---------------------------------------------------------------
    jal   x8, jal_target
    j     fail
jal_target:
    auipc x9, 0
    addi  x9, x9, -4               # address of the skipped "j fail"
    bne   x8, x9, fail

    # ---- every branch condition, taken and not-taken -----------------------
    addi  x10, x0, -5              # 0xFFFFFFFB
    addi  x11, x0, 3
    blt   x10, x11, b1             # taken
    j     fail
b1:
    bge   x11, x10, b2             # taken
    j     fail
b2:
    bltu  x10, x11, fail           # not taken (unsigned)
    bgeu  x11, x10, fail           # not taken (unsigned)
    beq   x10, x11, fail           # not taken
    bne   x10, x10, fail           # not taken
    bge   x10, x11, fail           # not taken
    blt   x11, x10, fail           # not taken
    bltu  x11, x10, b3             # taken (unsigned)
    j     fail
b3:
    bgeu  x10, x11, b4             # taken (unsigned)
    j     fail
b4:

    # ---- x0 as rs1 with a live rs2 (exercises read port 2 independently) ---
    addi  x17, x0, 7
    sub   x18, x0, x17             # 0 - 7 = -7
    addi  x19, x0, -7
    bne   x18, x19, fail
    beq   x0, x17, fail            # 0 == 7 is false; must not be taken

    # ---- backward branch: a negative offset sets B-type imm[11] ------------
    addi  x14, x0, 10
    addi  x15, x0, 0
loop:
    add   x15, x15, x14
    addi  x14, x14, -1
    bne   x14, x0, loop            # branches backwards
    addi  x16, x0, 55              # 10+9+...+1
    bne   x15, x16, fail

    # ---- FENCE and NOP decode without trapping -----------------------------
    fence
    nop

    # `fail` is placed BEFORE `pass` deliberately: falling off the end of the
    # test body must land on the fail path, so a core in which no branch or
    # jump is ever taken cannot reach `pass` by fall-through.
    j     pass

fail:
    addi  x24, x0, 0x400
    lui   x1, 0xBAADC
    addi  x1, x1, 0x0DE            # 0xBAADC0DE
    sw    x1, 0x100(x24)
    ebreak

pass:
    addi  x24, x0, 0x400
    lui   x1, 0x600DC
    addi  x1, x1, 0x0DE            # 0x600DC0DE
    sw    x1, 0x100(x24)
    ebreak
