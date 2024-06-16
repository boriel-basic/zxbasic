; Negates HL value (16 bit)
    push namespace core

__ABS16:
    bit 7, h
    ret z

__NEGHL:
    ld a, l			; HL = -HL
    cpl
    ld l, a
    ld a, h
    cpl
    ld h, a
    inc hl
    ret

    pop namespace

