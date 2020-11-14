; FASTCALL boolean xor 8 version.
; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
; Performs 32bit xor 32bit and returns the boolean

#include once <xor8.asm>

__XOR32:
    ld a, h
    or l
    or d
    or e
    ld c, a

    pop hl  ; RET address
    pop de
    ex (sp), hl
    ld a, h
    or l
    or d
    or e
    ld h, c
    jp __XOR8

