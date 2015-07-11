
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

    ld a, 0
    jp nz, __LTI2 ; go for sign it Not Zero
    ; At this point, DE = 0. So, check HL

    or h
    or l
    sub 1   ; If A = 0 => A = 0xFF & Carry
    sbc a, a; If Carry, A = 0xFF else, 0
    ret

