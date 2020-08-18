#ifdef ___PRINT_IS_USED___
#include once <print.asm>
#endif

#include once <const.asm>

COPY_ATTR:
	; Just copies current permanent attribs to temporal attribs
	; and sets print mode 
	PROC

	LOCAL INVERSE1
	LOCAL __REFRESH_TMP

INVERSE1 EQU 02Fh

	ld hl, (ATTR_P)
	ld (ATTR_T), hl

	ld hl, FLAGS2
	call __REFRESH_TMP
	
	ld hl, P_FLAG
	call __REFRESH_TMP


__SET_ATTR_MODE:		; Another entry to set print modes. A contains (P_FLAG)

#ifdef ___PRINT_IS_USED___
	LOCAL TABLE	
	LOCAL CONT2

	rra					; Over bit to carry
	ld a, (FLAGS2)
	rla					; Over bit in bit 1, Over2 bit in bit 2
	and 3				; Only bit 0 and 1 (OVER flag)

	ld c, a
	ld b, 0

	ld hl, TABLE
	add hl, bc
	ld a, (hl)
	ld (PRINT_MODE), a

	ld hl, (P_FLAG)
	xor a			; NOP -> INVERSE0
	bit 2, l
	jr z, CONT2
	ld a, INVERSE1 	; CPL -> INVERSE1

CONT2:
	ld (INVERSE_MODE), a
	ret

TABLE:
	nop				; NORMAL MODE
	xor (hl)		; OVER 1 MODE
	and (hl)		; OVER 2 MODE
	or  (hl)		; OVER 3 MODE 

#else
	ret
#endif

__REFRESH_TMP:
	ld a, (hl)
	and 10101010b
	ld c, a
	rra
	or c
	ld (hl), a
	ret

	ENDP

