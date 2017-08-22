#include once <lei8.asm>

__LTI16: ; Test 8 bit values HL < DE
         ; Returns result in A: 0 = False, !0 = True
    PROC
    LOCAL checkParity
    or a
    sbc hl, de
    jp po, checkParity
    ld a, h
    xor 0x80
checkParity:
    ld a, 0     ; False
    ret p
    inc a       ; True
    ret
    ENDP
