#include once <attr.asm>

push namespace core

; Sets the attribute at a given screen pixel address in hl
; HL contains the address in RAM for a given pixel (not a coordinate)
SET_PIXEL_ADDR_ATTR:
    ;; gets ATTR position with offset given in SCREEN_ADDR
    ld de, (SCREEN_ADDR)
    or a
    sbc hl, de
    ld a, h
    rrca
    rrca
    rrca
    and 3
    ld h, a

    ld de, (SCREEN_ATTR_ADDR)
    add hl, de  ;; Final screen addr
    jp __SET_ATTR2

pop namespace
