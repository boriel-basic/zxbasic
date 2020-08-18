; String slicing library
; HL = Str pointer
; DE = String start
; BC = String character end
; A register => 0 => the HL pointer wont' be freed from the HEAP
; e.g. a$(5 TO 10) => HL = a$; DE = 5; BC = 10

; This implements a$(X to Y) being X and Y first and 
; last characters respectively. If X > Y, NULL is returned

; Otherwise returns a pointer to a$ FROM X to Y (starting from 0)
; if Y > len(a$), then a$ will be padded with spaces (reallocating
; it in dynamic memory if needed). Returns pointer (HL) to resulting 
; string. NULL (0) if no memory for padding.
;

#include once <strlen.asm>
#include once <alloc.asm>
#include once <free.asm>

__STRSLICE:			; Callee entry
	pop hl			; Return ADDRESS
	pop bc			; Last char pos
	pop de			; 1st char pos
	ex (sp), hl		; CALLEE. -> String start

__STRSLICE_FAST:	; __FASTCALL__ Entry
	PROC

	LOCAL __CONT
	LOCAL __EMPTY
	LOCAL __FREE_ON_EXIT

	push hl			; Stores original HL pointer to be recovered on exit
	ex af, af'		; Saves A register for later

	push hl
	call __STRLEN
	inc bc			; Last character position + 1 (string starts from 0)	
	or a
	sbc hl, bc		; Compares length with last char position
	jr nc, __CONT	; If Carry => We must copy to end of string
	add hl, bc		; Restore back original LEN(a$) in HL
	ld b, h
	ld c, l			; Copy to the end of str
	ccf				; Clears Carry flag for next subtraction

__CONT:
	ld h, b	
	ld l, c			; HL = Last char position to copy (1 for char 0, 2 for char 1, etc)
	sbc hl, de		; HL = LEN(a$) - DE => Number of chars to copy
	jr z, __EMPTY	; 0 Chars to copy => Return HL = 0 (NULL STR)
	jr c, __EMPTY	; If Carry => Nothing to return (NULL STR)

	ld b, h
	ld c, l			; BC = Number of chars to copy
	inc bc
	inc bc			; +2 bytes for string length number

	push bc
	push de
	call __MEM_ALLOC
	pop de
	pop bc
	ld a, h
	or l
	jr z, __EMPTY	; Return if NULL (no memory)

	dec bc
	dec bc			; Number of chars to copy (Len of slice)

	ld (hl), c
	inc hl
	ld (hl), b
	inc hl			; Stores new string length

	ex (sp), hl		; Pointer to A$ now in HL; Pointer to new string chars in Stack
	inc hl
	inc hl			; Skip string length
	add hl, de		; Were to start from A$
	pop de			; Start of new string chars
	push de			; Stores it again
	ldir			; Copies BC chars
	pop de
	dec de
	dec de			; Points to String LEN start
	ex de, hl		; Returns it in HL
	jr __FREE_ON_EXIT

__EMPTY:			; Return NULL (empty) string
	pop hl
	ld hl, 0		; Return NULL


__FREE_ON_EXIT:
	ex af, af'		; Recover original A register
	ex (sp), hl		; Original HL pointer

	or a
	call nz, __MEM_FREE

	pop hl			; Recover result
	ret	
	
	ENDP	

