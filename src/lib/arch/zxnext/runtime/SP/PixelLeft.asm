;
; PixelLeft
; Jose Rodriguez 2012
;

; PixelLeft
;
; Adjusts screen address HL and Pixel bit A to move one pixel to the left
; on the display.  Start of line set Carry (Out of Screen)
;
; enter: HL = valid screen address
;        A = Bit Set
; exit : Carry = moved off screen
;        Carry' Set if moved off current ATTR CELL
;        HL = moves one character left, if needed
;        A = Bit Set with new pixel pos.
; used : AF, HL


    push namespace core

SP.PixelLeft:
    PROC

    LOCAL leave

    push de
    ld de, (SCREEN_ADDR)
    or a
    sbc hl, de  ; This always sets Carry = 0

    rlca    ; Sets new pixel bit 1 to the right
    jr nc, leave
    ex af, af' ; Signal in C' we've moved off current ATTR cell
    ld a,l
    dec a
    ld l,a
    cp 32      ; Carry if in screen
    ccf
    ld a, 1

leave:  ; Sets screen offset back again
    push af
    add hl, de
    pop af
    pop de
    ret

    ENDP
    pop namespace

#include once <sysvars.asm>
