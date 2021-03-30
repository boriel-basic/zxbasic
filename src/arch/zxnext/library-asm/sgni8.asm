; Returns SGN (SIGN) for 8 bits signed integer

    push namespace core

__SGNI8:
    or a
    ret z
    ld a, 1
    ret p
    neg
    ret

    pop namespace

