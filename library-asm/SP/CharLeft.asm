;
; CharLeft
; Alvin Albrecht 2002
;

;INCLUDE "SPconfig.def"
;XLIB SPCharLeft

; Char Left
;
; Adjusts screen address HL to move one character to the left
; on the display.  Start of line wraps to the previous row.
;
; enter: HL = valid screen address
;        Carry reset
; exit : Carry = moved off screen
;        HL = moves one character left, with line wrap
; used : AF, HL

;IF !DISP_HIRES

SP.CharLeft:
   ld a,l
   dec l
   or a
   ret nz
   ld a,h
   sub $08
   ld h,a
   cp $40
   ret

;ELSE

;.SPCharLeft
;   ld a,h
;   xor $20
;   ld h,a
;   cp $58
;   ccf
;   ret nc
;   ld a,l
;   dec l
;   or a
;   ret nz
;   ld a,h
;   sub $08
;   ld h,a
;   and $18
;   cp $18
;   ccf
;   ret

; ENDIF
