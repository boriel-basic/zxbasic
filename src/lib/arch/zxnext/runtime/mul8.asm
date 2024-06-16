    push namespace core

__MUL8:		; Performs 8bit x 8bit multiplication
    PROC
    ; 1st operand (byte) in A, 2nd operand into the stack (AF)
    pop hl	; return address
    ex (sp), hl ; CALLE convention

__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry
	; zx next 			
	ld e,a 			; 4t 	
	ld d,h 			; 4t 
	mul d,e 		; 8t 
	ld a,e			; 4			; 20t
    ret		; result = DE & A
	
    ENDP

    pop namespace
