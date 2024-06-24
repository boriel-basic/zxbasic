;
; PixelUp
; Alvin Albrecht 2002
;

; Pixel Up
;
; Adjusts screen address HL to move one pixel up in the display.
; (0,0) is located at the top left corner of the screen.
;
; enter: HL = valid screen address
; exit : Carry = moved off screen
;        HL = moves one pixel up
; used : AF, HL

    push namespace core

SP.PixelUp:
    PROC

    LOCAL leave

    push de
    ld de, (SCREEN_ADDR)
    or a
    sbc hl, de

    ld a,h
    dec h
    and $07
    jr nz, leave
    scf         ; sets C' to 1 (ATTR update needed)
    ex af, af'
    ld a,$08
    add a,h
    ld h,a
    ld a,l
    sub $20
    ld l,a
    jr nc, leave
    ld a,h
    sub $08
    ld h,a

leave:
    push af
    add hl, de
    pop af
    pop de
    ret

    ENDP

    pop namespace

#include once <sysvars.asm>
