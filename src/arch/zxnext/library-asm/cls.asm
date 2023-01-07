;; Clears the user screen (24 rows)

#include once <sysvars.asm>

    push namespace core

CLS:
    PROC

    ld hl, 0
    ld (COORDS), hl
    ld hl, SCR_SIZE
    ld (S_POSN), hl
    ld hl, (SCREEN_ADDR)
    ld (DFCC), hl
    ld (hl), 0
    ld d, h
    ld e, l
    inc de
    ld bc, 6143
    ldir

    ; Now clear attributes

    ld hl, (SCREEN_ATTR_ADDR)
    ld (DFCCL), hl
    ld d, h
    ld e, l
    inc de
    ld a, (ATTR_P)
    ld (hl), a
    ld bc, 767
    ldir
    ret

    ENDP

    pop namespace
