
#include once <sub32.asm>

__LEI32: ; Test 32 bit values Top of the stack <= HL,DE
    PROC
    LOCAL checkParity
    exx
    pop de ; Preserves return address
    exx

    call __SUB32

    exx
    push de ; Puts return address back
    exx

    ex af, af'
    ld a, h
    or l
    or e
    or d
    ld a, 1
    ret z

    ex af, af'
    jp po, checkParity
    ld a, d
    xor 0x80
checkParity:
    ld a, 0     ; False
    ret p
    inc a       ; True
    ret
    ENDP
