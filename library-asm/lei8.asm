__LEI8: ; Signed <= comparison for 8bit int
        ; A <= H (registers)
    PROC
    LOCAL checkParity
    sub h
    ld l, a
    ld a, 1
    ret z
    ld a, l
    jp po, checkParity
    xor 0x80
checkParity:
    ld a, 0
    ret p
    inc a
    ret
    ENDP
