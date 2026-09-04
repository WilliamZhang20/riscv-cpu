#!/usr/bin/env python3
"""Minimal two-pass RV32I assembler.

No RISC-V toolchain on this machine, so this exists purely to turn the test
programs in sim/ into $readmemh input. It covers RV32I plus a few pseudo-ops;
it is not a general assembler and makes no attempt at relocations or sections.

Usage: ./asm.py prog.s prog.hex
"""
import re
import sys

R = {  # name: (funct7, funct3)
    'add': (0x00, 0b000), 'sub': (0x20, 0b000), 'sll': (0x00, 0b001),
    'slt': (0x00, 0b010), 'sltu': (0x00, 0b011), 'xor': (0x00, 0b100),
    'srl': (0x00, 0b101), 'sra': (0x20, 0b101), 'or': (0x00, 0b110),
    'and': (0x00, 0b111),
}
I_ARITH = {  # name: funct3
    'addi': 0b000, 'slti': 0b010, 'sltiu': 0b011, 'xori': 0b100,
    'ori': 0b110, 'andi': 0b111,
}
I_SHIFT = {'slli': (0x00, 0b001), 'srli': (0x00, 0b101), 'srai': (0x20, 0b101)}
LOAD = {'lb': 0b000, 'lh': 0b001, 'lw': 0b010, 'lbu': 0b100, 'lhu': 0b101}
STORE = {'sb': 0b000, 'sh': 0b001, 'sw': 0b010}
BRANCH = {'beq': 0b000, 'bne': 0b001, 'blt': 0b100, 'bge': 0b101,
          'bltu': 0b110, 'bgeu': 0b111}

OP_LOAD, OP_IMM, OP_AUIPC = 0x03, 0x13, 0x17
OP_STORE, OP_REG, OP_LUI = 0x23, 0x33, 0x37
OP_BRANCH, OP_JALR, OP_JAL, OP_SYSTEM = 0x63, 0x67, 0x6F, 0x73

ABI = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4, 't0': 5, 't1': 6, 't2': 7,
    's0': 8, 'fp': 8, 's1': 9, 'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13,
    'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20,
    's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28, 't4': 29, 't5': 30, 't6': 31,
}


class AsmError(Exception):
    pass


def reg(tok):
    t = tok.strip().lower()
    if t in ABI:
        return ABI[t]
    m = re.fullmatch(r'x(\d+)', t)
    if not m or int(m.group(1)) > 31:
        raise AsmError(f'bad register {tok!r}')
    return int(m.group(1))


def const(tok, labels, pc):
    t = tok.strip()
    if t in labels:
        return labels[t]
    try:
        return int(t, 0)
    except ValueError:
        raise AsmError(f'bad immediate {tok!r}')


def fits(v, bits, signed=True):
    if signed:
        lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    else:
        lo, hi = 0, (1 << bits) - 1
    if not lo <= v <= hi:
        raise AsmError(f'immediate {v} does not fit in {bits} bits')
    return v & ((1 << bits) - 1)


def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3, op):
    imm &= 0xFFF
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | ((imm & 0x1F) << 7) | op


def enc_b(imm, rs2, rs1, f3, op):
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | \
           (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def enc_u(imm, rd, op):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(imm, rd, op):
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | \
           (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | \
           (rd << 7) | op


MEM_RE = re.compile(r'^\s*(-?\w+)\s*\(\s*(\w+)\s*\)\s*$')


def encode(mn, ops, pc, labels):
    if mn in R:
        f7, f3 = R[mn]
        return enc_r(f7, reg(ops[2]), reg(ops[1]), f3, reg(ops[0]), OP_REG)
    if mn in I_ARITH:
        v = fits(const(ops[2], labels, pc), 12)
        return enc_i(v, reg(ops[1]), I_ARITH[mn], reg(ops[0]), OP_IMM)
    if mn in I_SHIFT:
        f7, f3 = I_SHIFT[mn]
        sh = fits(const(ops[2], labels, pc), 5, signed=False)
        return enc_i((f7 << 5) | sh, reg(ops[1]), f3, reg(ops[0]), OP_IMM)
    if mn in LOAD:
        m = MEM_RE.match(ops[1])
        if not m:
            raise AsmError(f'bad address operand {ops[1]!r}')
        v = fits(const(m.group(1), labels, pc), 12)
        return enc_i(v, reg(m.group(2)), LOAD[mn], reg(ops[0]), OP_LOAD)
    if mn in STORE:
        m = MEM_RE.match(ops[1])
        if not m:
            raise AsmError(f'bad address operand {ops[1]!r}')
        v = fits(const(m.group(1), labels, pc), 12)
        return enc_s(v, reg(ops[0]), reg(m.group(2)), STORE[mn], OP_STORE)
    if mn in BRANCH:
        off = const(ops[2], labels, pc) - pc
        if off & 1:
            raise AsmError('misaligned branch target')
        return enc_b(fits(off, 13), reg(ops[1]), reg(ops[0]), BRANCH[mn],
                     OP_BRANCH)
    if mn == 'lui':
        return enc_u(fits(const(ops[1], labels, pc), 20, signed=False),
                     reg(ops[0]), OP_LUI)
    if mn == 'auipc':
        return enc_u(fits(const(ops[1], labels, pc), 20, signed=False),
                     reg(ops[0]), OP_AUIPC)
    if mn == 'jal':
        rd, tgt = (ops[0], ops[1]) if len(ops) == 2 else ('ra', ops[0])
        return enc_j(fits(const(tgt, labels, pc) - pc, 21), reg(rd), OP_JAL)
    if mn == 'jalr':
        if len(ops) == 2:                      # jalr rd, off(rs1)
            m = MEM_RE.match(ops[1])
            if not m:
                raise AsmError(f'bad address operand {ops[1]!r}')
            off, rs1 = const(m.group(1), labels, pc), reg(m.group(2))
            rd = reg(ops[0])
        else:                                  # jalr rd, rs1, off
            rd, rs1 = reg(ops[0]), reg(ops[1])
            off = const(ops[2], labels, pc)
        return enc_i(fits(off, 12), rs1, 0b000, rd, OP_JALR)
    # pseudo-ops
    if mn == 'nop':
        return enc_i(0, 0, 0b000, 0, OP_IMM)
    if mn == 'j':
        return enc_j(fits(const(ops[0], labels, pc) - pc, 21), 0, OP_JAL)
    if mn == 'mv':
        return enc_i(0, reg(ops[1]), 0b000, reg(ops[0]), OP_IMM)
    if mn == 'fence':
        return 0x0FF0000F              # fence iorw, iorw
    if mn == 'ecall':
        return enc_i(0x000, 0, 0b000, 0, OP_SYSTEM)
    if mn == 'ebreak':
        return enc_i(0x001, 0, 0b000, 0, OP_SYSTEM)
    raise AsmError(f'unknown mnemonic {mn!r}')


def split_ops(rest):
    """Split on commas, but keep off(reg) intact."""
    return [o.strip() for o in rest.split(',') if o.strip()]


def parse(src):
    """Pass 1: strip comments, collect labels, return [(pc, mnemonic, ops)]."""
    labels, items, pc = {}, [], 0
    for lineno, raw in enumerate(src.splitlines(), 1):
        line = raw.split('#')[0].strip()
        while line:
            m = re.match(r'^([A-Za-z_.$][\w.$]*)\s*:\s*', line)
            if not m:
                break
            labels[m.group(1)] = pc
            line = line[m.end():].strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mn = parts[0].lower()
        ops = split_ops(parts[1]) if len(parts) > 1 else []
        items.append((pc, mn, ops, lineno))
        pc += 4
    return labels, items


def assemble(src):
    labels, items = parse(src)
    words = []
    for pc, mn, ops, lineno in items:
        try:
            words.append(encode(mn, ops, pc, labels))
        except (AsmError, IndexError) as e:
            raise SystemExit(f'asm.py: line {lineno}: {mn} {",".join(ops)}: {e}')
    return words


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    words = assemble(open(sys.argv[1]).read())
    with open(sys.argv[2], 'w') as f:
        for w in words:
            f.write(f'{w:08x}\n')
    print(f'asm.py: {len(words)} instructions -> {sys.argv[2]}')


if __name__ == '__main__':
    main()
