#include once <stackf.asm>

    push namespace core

LN: ; Computes Ln(x) using ROM FP-CALC
    call __FPSTACK_PUSH

    rst 28h	; ROM CALC
    defb 25h
    defb 38h ; END CALC

    jp __FPSTACK_POP

    pop namespace
