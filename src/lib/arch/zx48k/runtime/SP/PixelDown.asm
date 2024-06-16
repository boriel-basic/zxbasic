;
; PixelDown
; Alvin Albrecht 2002
;

; Pixel Down
;
; Adjusts screen address HL to move one pixel down in the display.
; (0,0) is located at the top left corner of the screen.
;
; enter: HL = valid screen address
; exit : Carry = moved off screen
;        Carry'= moved off current cell (needs ATTR update)
;        HL = moves one pixel down
; used : AF, HL

    push namespace core

SP.PixelDown:
    PROC
    LOCAL leave

    push de
    ld de, (SCREEN_ADDR)
    or a
    sbc hl, de
    inc h
    ld a,h
    and $07
    jr nz, leave
    scf         ;  Sets carry on F', which flags ATTR must be updated
    ex af, af'
    ld a,h
    sub $08
    ld h,a
    ld a,l
    add a,$20
    ld l,a
    jr nc, leave
    ld a,h
    add a,$08
    ld h,a
    cp $19     ; carry = 0 => Out of screen
    jr c, leave ; returns if out of screen
    ccf
    pop de
    ret

leave:
    add hl, de ; This always sets Carry = 0
    pop de
    ret

    ENDP
    pop namespace

#include once <sysvars.asm>