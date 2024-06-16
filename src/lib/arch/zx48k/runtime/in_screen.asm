#include once <sposn.asm>
#include once <error.asm>

    push namespace core

__IN_SCREEN:
    ; Returns NO carry if current coords (D, E)
    ; are OUT of the screen limits

    PROC
    LOCAL __IN_SCREEN_ERR

    ld hl, SCR_SIZE
    ld a, e
    cp l
    jr nc, __IN_SCREEN_ERR	; Do nothing and return if out of range

    ld a, d
    cp h
    ret c                       ; Return if carry (OK)

__IN_SCREEN_ERR:
__OUT_OF_SCREEN_ERR:
    ; Jumps here if out of screen
    ld a, ERROR_OutOfScreen
    jp __STOP   ; Saves error code and exits

    ENDP

    pop namespace
