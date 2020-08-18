			; --------------------------------
__DIVU8:	; 8 bit unsigned integer division 
			; Divides (Top of stack, High Byte) / A
	pop hl	; --------------------------------
	ex (sp), hl	; CALLEE

__DIVU8_FAST:	; Does A / H
	ld l, h
	ld h, a		; At this point do H / L

	ld b, 8
	xor a		; A = 0, Carry Flag = 0
	
__DIV8LOOP:
	sla	h		
	rla			
	cp	l		
	jr	c, __DIV8NOSUB
	sub	l		
	inc	h		

__DIV8NOSUB:	
	djnz __DIV8LOOP

	ld	l, a		; save remainder
	ld	a, h		; 
	
	ret			; a = Quotient, 


				; --------------------------------
__DIVI8:		; 8 bit signed integer division Divides (Top of stack) / A
	pop hl		; --------------------------------
	ex (sp), hl

__DIVI8_FAST:
	ld e, a		; store operands for later
	ld c, h

	or a		; negative?
	jp p, __DIV8A
	neg			; Make it positive

__DIV8A:
	ex af, af'
	ld a, h
	or a
	jp p, __DIV8B
	neg
	ld h, a		; make it positive

__DIV8B:
	ex af, af'

	call __DIVU8_FAST

	ld a, c
	xor l		; bit 7 of A = 1 if result is negative

	ld a, h		; Quotient
	ret p		; return if positive	

	neg
	ret
	

__MODU8:		; 8 bit module. REturns A mod (Top of stack) (unsigned operands)
	pop hl
	ex (sp), hl	; CALLEE

__MODU8_FAST:	; __FASTCALL__ entry
	call __DIVU8_FAST
	ld a, l		; Remainder

	ret		; a = Modulus


__MODI8:		; 8 bit module. REturns A mod (Top of stack) (For singed operands)
	pop hl
	ex (sp), hl	; CALLEE

__MODI8_FAST:	; __FASTCALL__ entry
	call __DIVI8_FAST
	ld a, l		; remainder

	ret		; a = Modulus

