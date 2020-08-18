__LEI8: ; Signed <= comparison for 8bit int
        ; A <= H (registers)
    PROC
    LOCAL checkParity
    sub h
    jr nz, __LTI
    inc a
    ret

__LTI8:  ; Test 8 bit values A < H
    sub h

__LTI:   ; Generic signed comparison
    jp po, checkParity
    xor 0x80
checkParity:
    ld a, 0     ; False
    ret p
    inc a       ; True
    ret
    ENDP
