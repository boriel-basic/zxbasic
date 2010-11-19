; Exchanges current DE HL with the
; ones in the stack

__SWAP32:
	pop bc ; Return address

	exx
	pop hl	; exx'
	pop de

	exx
	push de ; exx
	push hl

	exx		; exx '
	push de
	push hl
	
	exx		; exx
	pop hl
	pop de

	push bc

	ret

