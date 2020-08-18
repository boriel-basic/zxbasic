; SUB32 
; Perform TOP of the stack - DEHL
; Pops operand out of the stack (CALLEE)
; and returns result in DEHL. Carry an Z are set correctly

__SUB32:
	exx
	pop bc		; saves return address in BC'
	exx

	or a        ; clears carry flag
	ld b, h     ; Operands come reversed => BC <- HL,  HL = HL - BC
	ld c, l
	pop hl
	sbc hl, bc
	ex de, hl

	ld b, h	    ; High part (DE) now in HL. Repeat operation
	ld c, l
	pop hl
	sbc hl, bc
	ex de, hl   ; DEHL now has de 32 bit result

	exx
	push bc		; puts return address back
	exx
	ret
