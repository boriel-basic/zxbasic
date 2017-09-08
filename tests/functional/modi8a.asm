	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	ld a, (_a)
	ld hl, (_a - 1)
	call __MODI8_FAST
	ld hl, (_a - 1)
	call __MODI8_FAST
	ld (_a), a
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
#line 1 "div8.asm"
	
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
	
#line 24 "modi8a.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
