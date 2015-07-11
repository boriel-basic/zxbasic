; SUB32 
; TOP of the stack - DEHL
; Pops operand out of the stack (CALLEE)
; and returns result in DEHL
; Operands come reversed => So we swap then using EX (SP), HL

__SUB32:
	exx
	pop bc		; Return address
	exx

	ex (sp), hl
	pop bc
	or a 
	sbc hl, bc

	ex de, hl
	ex (sp), hl
	pop bc
	sbc hl, bc
	ex de, hl

	exx
	push bc		; Put return address
	exx
	ret
	


