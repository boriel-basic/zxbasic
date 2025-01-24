;; Performs a faster multiply for little 16bit numbs
#include once <arith/mul16.asm>

    push namespace core

__FMUL16:
    xor a
    or h
    jp nz, __MUL16_FAST
    or l
    ret z

    cp 33
    jp nc, __MUL16_FAST

    ld b, l
    ld l, h  ; HL = 0

1:
    add hl, de
    djnz 1b
    ret

    pop namespace
