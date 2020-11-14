#include once <alloc.asm>

; Loads a string (ptr) from HL
; and duplicates it on dynamic memory again
; Finally, it returns result pointer in HL

__ILOADSTR:		; This is the indirect pointer entry HL = (HL)
		ld a, h
		or l
		ret z
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a

__LOADSTR:		; __FASTCALL__ entry
		ld a, h
		or l
		ret z	; Return if NULL

		ld c, (hl)
		inc hl
		ld b, (hl)
		dec hl  ; BC = LEN(a$)

		inc bc
		inc bc	; BC = LEN(a$) + 2 (two bytes for length)

		push hl
		push bc
		call __MEM_ALLOC
		pop bc  ; Recover length
		pop de  ; Recover origin

		ld a, h
		or l
		ret z	; Return if NULL (No memory)

		ex de, hl ; ldir takes HL as source, DE as destiny, so SWAP HL,DE
		push de	; Saves destiny start
		ldir	; Copies string (length number included)
		pop hl	; Recovers destiny in hl as result
		ret
