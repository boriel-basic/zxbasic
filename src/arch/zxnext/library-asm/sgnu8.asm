; Returns SGN (SIGN) for 8 bits unsigned integera

    push namespace core

__SGNU8:
    or a
    ret z
    ld a, 1
    ret

    pop namespace

