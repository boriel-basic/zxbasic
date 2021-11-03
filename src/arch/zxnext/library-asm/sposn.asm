#include once <sysvars.asm>

; Printing positioning library.
    push namespace core

    PROC

__LOAD_S_POSN:		; Loads into DE current ROW, COL print position from S_POSN mem var.
    ld de, (S_POSN)
    ld hl, (MAXX)
    or a
    sbc hl, de
    ex de, hl
    ret


__SAVE_S_POSN:		; Saves ROW, COL from DE into S_POSN mem var.
    ld hl, (MAXX)
    or a
    sbc hl, de
    ld (S_POSN), hl ; saves it again
    ret

    ENDP

    pop namespace
