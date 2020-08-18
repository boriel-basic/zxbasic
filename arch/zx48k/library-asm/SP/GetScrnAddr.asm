;
; GetScrnAddr
; Alvin Albrecht 2002
;

;INCLUDE "SPconfig.def"
;XLIB SPGetScrnAddr

; Get Screen Address
;
; Computes the screen address given a valid pixel coordinate.
; (0,0) is located at the top left corner of the screen.
;
; enter: a = h = y coord
;        l = x coord
;        In hi-res mode, Carry is most significant bit of x coord (0..511 pixels)
; exit : de = screen address, b = pixel mask
; uses : af, b, de, hl

;IF !DISP_HIRES

SPGetScrnAddr:
   and $07
   or $40
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
   ret

;ELSE
;
;.SPGetScrnAddr
;   ld b,0
;   ld d,b
;   rr l
;   rl b
;   srl l
;   rl b
;   srl l
;   rl b
;   srl l
;   jr nc, notodd
;   ld d,$20
;
;.notodd
;   ld a,b
;  or a
;   ld a,$80
;  jr z, norotate
;
;.rotloop
;   rra
;   djnz rotloop

;.norotate
;   ld b,a
;   ld a,h
;   and $07
;   or $40
;   or d
;   ld d,a
;   ld a,h
;   rra
;   rra
;   rra
;   and $18
;   or d
;   ld d,a
;
;   ld a,h
;   rla
;   rla
;   and $e0
 ;  or l
;   ld e,a
;   ret

;ENDIF
