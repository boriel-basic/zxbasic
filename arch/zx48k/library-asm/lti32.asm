
#include once <sub32.asm>

__LTI32: ; Test 32 bit values in Top of the stack < HLDE
    PROC
    LOCAL checkParity
    exx
    pop de ; Preserves return address
    exx

    call __SUB32

    exx
    push de ; Restores return address
    exx

    jp po, checkParity
    ld a, d
    xor 0x80
checkParity:
    ld a, 0     ; False
    ret p
    inc a       ; True
    ret
    ENDP
