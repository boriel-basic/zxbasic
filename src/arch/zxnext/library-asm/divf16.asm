#include once <div32.asm>


__DIVF16:	; 16.16 Fixed point Division (signed)
	
            ; DE.HL = Dividend, Stack Top = Divisor
            ; A = Dividend, B = Divisor => A / B
                exx
                pop hl   ; return address
                pop de   ; low part
                ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
				ex de, hl   ; D'E'.H'L' Dividend

__DIVF16START: ; FAST Entry: DEHL => Dividend, D'E'H'L' => Divisor
		ld a, d	 ; Save sign
		ex af, af'
		bit 7, d ; Negative?
		call nz, __NEG32 ; Negates DEHL

		exx		; Now works with D'E'.H'L'
		ex af, af'
		xor d
		ex af, af'  ; Stores sign of the result for later

		bit 7, d ; Negative?
		call nz, __NEG32
		exx		 ; Now we have DE.HL => Dividend

		ld b, 16

__SHIFTALOOP:		; Tries to shift Dividend to the left
        bit 7, d
		jp nz, __SHIFTB
        add hl, hl
		ex de, hl
        adc hl, hl
		ex de, hl
        djnz __SHIFTALOOP
        jp __DOF16_DIVRDY

__SHIFTB:       ; Cannot shift Dividend more to the left, try to shift Divisor to the right
        ld a, b
        exx
        ld b, a
                ; Divisor is in DEHL
__SHIFTBLOOP:
        bit 1, l
		jp nz, __DOF16_DIVIDE
        sra d
        rr e
        rr h
        rr l
        djnz __SHIFTBLOOP

__DOF16_DIVIDE:
        ld a, b
        exx
        ld b, a

__DOF16_DIVRDY:
		exx
		ex de, hl
        push bc
		call __DIVU32START
		pop bc

		xor a
		or b
		jp z, __ENDF16DIV

__SHIFTCLOOP:
		add hl, hl	; Shift DECIMAL PART << 1
		ex de, hl		
		adc hl, hl  ; Shift INTEGER PART << 1 Plus Carry
		ex de, hl		
		djnz __SHIFTCLOOP

__ENDF16DIV: 	   ; Put the sign on the result
		ex af, af' ; Recovers sign
		and 128	   ; positive?
		ret z
		jp __NEG32 ; Negates DEHL and returns from there

