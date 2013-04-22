#include once <lti8.asm>

__LEI8: ; Signed <= comparison for 8bit int
        ; A <= H (registers)
        sub h
        jp nz, __LTI ; not 0, proceed as A < H
        dec a   ; Sets A to True
        ret
