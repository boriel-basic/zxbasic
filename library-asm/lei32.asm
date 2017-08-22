
#include once <lti8.asm>
#include once <sub32.asm>

__LEI32: ; Test 32 bit values HLDE < Top of the stack
    exx
    pop de ; Preserves return address
    exx

    call __SUB32

    exx
    push de ; Restores return address
    exx

    ld a, 1
    ret c
    dec a
    ret
