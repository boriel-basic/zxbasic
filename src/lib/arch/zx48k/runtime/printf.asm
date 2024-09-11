#include once <printstr.asm>
#include once <sysvars.asm>
#include once <str.asm>

    push namespace core

__PRINTF:	; Prints a Fixed point Number stored in C ED LH
    PROC

    call __STR
    call __PRINT_STR
    ret

RECLAIM2 EQU 19E8h

    ENDP

    pop namespace
