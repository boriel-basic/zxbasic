; Substring assigment eg. LET a$(p0 TO p1) = "xxxx"
; HL = Start of string
; TOP of the stack -> p1 (16 bit, unsigned)
; TOP -1 of the stack -> p0 register 
; TOP -2 Flag (popped out in A register)
; 		A Register	=> 0 if HL is not freed from memory
;					=> Not 0 if HL must be freed from memory on exit
; TOP -3 B$ address

#include once <free.asm>

__LETSUBSTR:
	PROC

	LOCAL __CONT0
	LOCAL __CONT1
	LOCAL __CONT2
	LOCAL __FREE_STR
	LOCAL __FREE_STR0

	exx
	pop hl ; Return address
	pop de ; p1
	pop bc ; p0
	exx

	pop af ; Flag
	ex af, af'	; Save it for later

	pop de ; B$

	exx
	push hl ; push ret addr back
	exx

	ld a, h
	or l
	jp z, __FREE_STR0 ; Return if null
	
	ld c, (hl)
	inc hl
	ld b, (hl) ; BC = Str length
	inc hl	; HL = String start
	push bc

	exx
	ex de, hl
	or a
	sbc hl, bc ; HL = Length of string requester by user
	inc hl	   ; len (a$(p0 TO p1)) = p1 - p0 + 1
	ex de, hl  ; Saves it in DE

	pop hl	   ; HL = String length
	exx
	jp c, __FREE_STR0	   ; Return if greather
	exx		   ; Return if p0 > p1

	or a
	sbc hl, bc ; P0 >= String length?
	exx

	jp z, __FREE_STR0	   ; Return if equal
	jp c, __FREE_STR0	   ; Return if greather

	exx
	add hl, bc ; Add it back

	sbc hl, de ; Length of substring > string => Truncate it
	add hl, de ; add it back
	jr nc, __CONT0 ; Length of substring within a$
	
	ld d, h
	ld e, l	   ; Truncate length of substring to fit within the strlen
	
__CONT0:	   ; At this point DE = Length of subtring to copy
			   ; BC = start of char to copy
	push de

	push bc
	exx
	pop bc

	add hl, bc ; Start address (within a$) so copy from b$ (in DE)

	push hl
	exx
	pop hl	   ; Start address (within a$) so copy from b$ (in DE)

	ld b, d	   ; Length of string
	ld c, e

	ld (hl), ' ' 
	ld d, h
	ld e, l
	inc de
	dec bc
	ld a, b
	or c
	jr z, __CONT2

	; At this point HL = DE = Start of Write zone in a$
	; BC = Number of chars to write

	ldir

__CONT2:

	pop bc	; Recovers Length of string to copy
	exx
	ex de, hl  ; HL = Source, DE = Target
	
	ld a, h
	or l
	jp z, __FREE_STR ; Return if B$ is NULL

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	ld a, b
	or c
	jp z, __FREE_STR ; Return if len(b$) = 0

	; Now if len(b$) < len(char to copy), copy only len(b$) chars

	push de
	push hl
	push bc
	exx
	pop hl	; LEN (b$)
	or a
	sbc hl, bc
	add hl, bc
	jr nc, __CONT1

	; If len(b$) < len(to copy)
	ld b, h ; BC = len(to copy)
	ld c, l

__CONT1:
	pop hl	
	pop de
	ldir	; Copy b$ into a$(x to y)

	exx
	ex de, hl

__FREE_STR0:
	ex de, hl

__FREE_STR:
	ex af, af'
	or a		; If not 0, free 
	jp nz, __MEM_FREE
	ret

	ENDP

