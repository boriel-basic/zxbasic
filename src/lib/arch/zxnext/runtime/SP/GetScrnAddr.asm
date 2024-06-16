;
; GetScrnAddr
; Alvin Albrecht 2002
;

; Get Screen Address
;
; Computes the screen address given a valid pixel coordinate.
; (0,0) is located at the top left corner of the screen.
;
; enter: h = y coord
;        l = x coord
;        In hi-res mode, Carry is most significant bit of x coord (0..511 pixels)
; exit : de = screen address, b = pixel mask
; uses : af, b, de, hl

    push namespace core
    PROC
    LOCAL rotloop, norotate

SPGetScrnAddr:
    ld a,h
    and $07
    ld d,a
    ld a,h
    rra
    rra
    rra
    and $18
    or d
    ld d,a

    ld a,l
    and $07
    ld b,a
    ld a,$80
    jr z, norotate

rotloop:
    rra
    djnz rotloop

norotate:
    ld b,a
    srl l
    srl l
    srl l
    ld a,h
    rla
    rla
    and $e0
    or l
    ld e,a
    ld hl, (SCREEN_ADDR)
    add hl, de
    ex de, hl
    ret

    ENDP
    pop namespace

#include once <sysvars.asm>
