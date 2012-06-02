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


SP.PixelLeft:
    rlca    ; Sets new pixel bit 1 to the right
    ret nc
    ex af, af' ; Signal in C' we've moved off current ATTR cell
    ld a,l
    dec a
    ld l,a
    cp 32      ; Carry if in screen
    ccf
    ld a, 1
    ret

