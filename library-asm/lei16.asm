
#include once <lti8.asm>

__LEI16: ; Test 8 bit values HL < DE
        ; Returns result in A: 0 = False, !0 = True
        xor a
        sbc hl, de
        jp nz, __LTI2
        dec a
        ret

