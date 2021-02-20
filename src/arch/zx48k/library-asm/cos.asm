#include once <stackf.asm>

    push namespace core

COS: ; Computes COS using ROM FP-CALC
    call __FPSTACK_PUSH

    rst 28h	; ROM CALC
    defb 20h ; COS
    defb 38h ; END CALC

    jp __FPSTACK_POP

    pop namespace

