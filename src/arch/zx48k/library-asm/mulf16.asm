#include once <neg32.asm>
#include once <_mul32.asm>

__MULF16:		; 
        ld      a, d            ; load sgn into a
        ex      af, af'         ; saves it
        call    __ABS32         ; convert to positive

		exx 
		pop hl ; Return address
		pop de ; Low part
		ex (sp), hl ; CALLEE caller convention; Now HL = Hight part, (SP) = Return address
		ex de, hl	; D'E' = High part (B),  H'L' = Low part (B) (must be in DE)

        ex      af, af'
        xor     d               ; A register contains resulting sgn
        ex      af, af'
        call    __ABS32         ; convert to positive

		call __MUL32_64START

; rounding (was not included in zx81)
__ROUND_FIX:					; rounds a 64bit (32.32) fixed point number to 16.16
								; result returned in dehl
								; input in h'l'hlb'c'ac
        sla     a               ; result bit 47 to carry
        exx
        ld      hl,0            ; ld does not change carry
        adc     hl,bc           ; hl = hl + 0 + carry
		push	hl

        exx
        ld      bc,0
        adc     hl,bc           ; hl = hl + 0 + carry        
		ex		de, hl
		pop		hl              ; rounded result in de.hl

        ex      af, af'         ; recovers result sign
        or      a
        jp      m, __NEG32      ; if negative, negates it
       
		ret					
       
