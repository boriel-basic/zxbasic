; Returns len if a string
; If a string is NULL, its len is also 0
; Result returned in HL

__STRLEN:	; Direct FASTCALL entry
		ld a, h
		or l
		ret z

		ld a, (hl)
		inc hl
		ld h, (hl)  ; LEN(str) in HL
		ld l, a
		ret


