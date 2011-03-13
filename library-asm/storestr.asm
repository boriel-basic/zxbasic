; Stores value of current string pointed by DE register into address pointed by HL
; Returns DE = Address pointer 
; Returns HL = HL

#include once <strcpy.asm>

__STORE_STR:
	push de		; Pointer to b$
	push hl		; Array pointer to variable memory address

	ld b, (hl)
	inc hl
	ld h, (hl)
	ld l, b		; Loads HL = (HL)

	call __STRASSIGN	; HL (a$) = DE (b$); HL changed to a new dynamic memory allocation
	ex de, hl			; DE = new address of a$
	pop hl		; Recover variable memory address pointer

	ld (hl), e
	inc hl
	ld (hl), d  ; Stores a$ ptr into elemem ptr

	pop hl		; Returns ptr to b$ in HL (Caller might needed to free it from memory)
	ret
