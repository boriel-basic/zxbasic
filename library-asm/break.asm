#include once <error.asm>


; Check if BREAK is pressed
; Return if not. Else Raises
; L BREAK Into Program Error
; HL contains the line number we want to appear in the error msg.

CHECK_BREAK:
    PROC
    LOCAL PPC, TS_BRK

    call TS_BRK
    ret c

    ld (PPC), HL
    ld a, ERROR_BreakIntoProgram
    jp __ERROR

PPC EQU 23621
TS_BRK EQU 8020

    ENDP

