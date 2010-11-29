#include once <realloc.asm>

; String library


__STRASSIGN: ; Performs a$ = b$ (HL = address of a$; DE = Address of b$)
		PROC

		LOCAL __STRREALLOC
		LOCAL __STRCONTINUE
		LOCAL __B_IS_NULL
		LOCAL __NOTHING_TO_COPY

		ld b, d
		ld c, e
		ld a, b
		or c
		jr z, __B_IS_NULL

		ex de, hl
		ld c, (hl)
		inc hl
		ld b, (hl)
		dec hl		; BC = LEN(b$)
		ex de, hl	; DE = &b$

__B_IS_NULL:		; Jumps here if B$ pointer is NULL
		inc bc
		inc bc		; BC = BC + 2  ; (LEN(b$) + 2 bytes for storing length)

		push de
		push hl

		ld a, h
		or l
		jr z, __STRREALLOC

		dec hl
		ld d, (hl)
		dec hl
		ld e, (hl)	; DE = MEMBLOCKSIZE(a$)
		dec de
		dec de		; DE = DE - 2  ; (Membloksize takes 2 bytes for memblock length)

		ld h, b
		ld l, c		; HL = LEN(b$) + 2  => Minimum block size required
		ex de, hl	; Now HL = BLOCKSIZE(a$), DE = LEN(b$) + 2

		or a		; Prepare to subtract BLOCKSIZE(a$) - LEN(b$)
		sbc hl, de  ; Carry if len(b$) > Blocklen(a$)
		jr c, __STRREALLOC ; No need to realloc
		; Need to reallocate at least to len(b$) + 2
		ex de, hl	; DE = Remaining bytes in a$ mem block.
		ld hl, 4	
		sbc hl, de  ; if remaining bytes < 4 we can continue
		jr nc,__STRCONTINUE ; Otherwise, we realloc, to free some bytes

__STRREALLOC:
		pop hl
		call __REALLOC	; Returns in HL a new pointer with BC bytes allocated
		push hl 

__STRCONTINUE:	;   Pops hl and de SWAPPED
		pop de	;	DE = &a$
		pop hl	; 	HL = &b$

		ld a, d		; Return if not enough memory for new length
		or e
		ret z		; Return if DE == NULL (0)

__STRCPY:	; Copies string pointed by HL into string pointed by DE
			; Returns DE as HL (new pointer)
		ld a, h
		or l
		jr z, __NOTHING_TO_COPY
		ld c, (hl)
		inc hl
		ld b, (hl)
		dec hl
		inc bc
		inc bc
		push de
		ldir
		pop hl
		ret

__NOTHING_TO_COPY:
		ex de, hl
		ld (hl), e
		inc hl
		ld (hl), d
		dec hl
		ret

		ENDP

