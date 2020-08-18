; Computes A % B for fixed values

#include once <divf16.asm>
#include once <mulf16.asm>

__MODF16:
            ; 16.16 Fixed point Division (signed)
            ; DE.HL = Divisor, Stack Top = Divider
            ; A = Dividend, B = Divisor => A % B

PROC
    LOCAL TEMP

TEMP EQU 23698       ; MEMBOT

    pop bc              ; ret addr
    ld (TEMP), bc       ; stores it on MEMBOT temporarily
	ld (TEMP + 2), hl   ; stores HP of divider 
	ld (TEMP + 4), de   ; stores DE of divider

    call __DIVF16
	rlc d				; Sign into carry
	sbc a, a			; a register = -1 sgn(DE), or 0
	ld d, a
	ld e, a				; DE = 0 if it was positive or 0; -1 if it was negative
    
	ld bc, (TEMP + 4)	; Pushes original divider into the stack
	push bc
	ld bc, (TEMP + 2)
	push bc
	
    ld bc, (TEMP)    ; recovers return address
    push bc
    jp __MULF16			; multiplies and return from there

ENDP

