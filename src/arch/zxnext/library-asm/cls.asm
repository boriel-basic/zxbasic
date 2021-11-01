;; Clears the user screen (24 rows)

#include once <sposn.asm>
#include once <sysvars.asm>

    push namespace core

CLS:
    PROC

    ld hl, 0
    ld (COORDS), hl
    ld hl, 1821h
    ld (S_POSN), hl
    ld hl, (SCREEN_ADDR)
    ld (hl), 0
    ld d, h
    ld e, l
    inc de
    ld bc, 6144
    ldir

    ; Now clear attributes

    ld hl, (SCREEN_ATTR_ADDR)
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

