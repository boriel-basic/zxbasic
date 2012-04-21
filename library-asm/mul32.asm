#include once <_mul32.asm>

__MUL32:	; multiplies 32 bit un/signed integer.
			; First operand stored in DEHL, and 2nd onto stack
			; Lowest part of 2nd operand on top of the stack
			; returns the result in DE.HL
		exx
		pop hl	; Return ADDRESS
		pop de	; Low part
		ex (sp), hl ; CALLEE -> HL = High part
		ex de, hl
		call __MUL32_64START

__TO32BIT:  ; Converts H'L'HLB'C'AC to DEHL (Discards H'L'HL)
		exx
		push bc
		exx
		pop de
		ld h, a
		ld l, c
		ret


