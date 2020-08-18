; -------------------------------------------------------------
; 32 bit logical NOT
; -------------------------------------------------------------

__NOT32:	; A = ¬A 
	ld a, d
	or e
	or h
	or l
	sub 1	; Gives CARRY only if 0
	sbc a, a; Gives 0 if not carry, FF otherwise
	ret


