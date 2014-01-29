__OR32:  ; Performs logical operation A AND B
		 ; between DEHL and TOP of the stack.
		 ; Returns A = 0 (False) or A = FF (True)

	ld a, h
	or l
	or d
	or e

	pop hl ; Return address

	pop de	
	or d
	or e

	pop de	
	or d
	or e   ; A = 0 only if DEHL and TOP of the stack = 0

	jp (hl) ; Faster "Ret"


