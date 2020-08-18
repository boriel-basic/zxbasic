#include once <error.asm>


; Check if BREAK is pressed
; Return if not. Else Raises
; L BREAK Into Program Error
; HL contains the line number we want to appear in the error msg.

CHECK_BREAK:
    PROC
    LOCAL PPC, TS_BRK, NO_BREAK

    push af
    call TS_BRK
    jr c, NO_BREAK

    ld (PPC), hl ; line num
    ld a, ERROR_BreakIntoProgram
    jp __ERROR   ; this stops the program and exits to BASIC

NO_BREAK:
    pop af
    pop hl       ; ret address
    ex (sp), hl  ; puts it back into the stack and recovers initial HL
    ret

PPC EQU 23621
TS_BRK EQU 8020

    ENDP

