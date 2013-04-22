;
; CharRight
; Alvin Albrecht 2002
;

;INCLUDE "SPconfig.def"
;XLIB SPCharRight

; Char Right
;
; Adjusts screen address HL to move one character to the right
; on the display.  End of line wraps to the next row.
;
; enter: HL = valid screen address
;        Carry reset
; exit : Carry = moved off screen
;        HL = moves one character right, with line wrap
; used : AF, HL

;IF !DISP_HIRES

SP.CharRight:
   inc l
   ret nz
   ld a,8
   add a,h
   ld h,a
   cp $58
   ccf
   ret

;ELSE

;.SPCharRight
;   ld a,h
;   xor $20
;   ld h,a
;   cp $58
;   ret nc
;   inc l
;   ret nz
;   ld a,8
;   add a,h
;   ld h,a
;   cp $58
;   ccf
;   ret

; ENDIF
