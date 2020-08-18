__LEI16:
    PROC
    LOCAL checkParity
    or a
    sbc hl, de
    ld a, 1
    ret z
    jp po, checkParity
    ld a, h
    xor 0x80
checkParity:
    ld a, 0     ; False
    ret p
    inc a       ; True
    ret
    ENDP
