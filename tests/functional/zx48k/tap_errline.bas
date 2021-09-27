
asm
    push    hl
    push    de
    push    af

    ld      hl,16384
    ld      de,16385
    ld      a,(hl)
    ex      hl,de

    pop     af
    pop     de
    pop     hl
end asm
