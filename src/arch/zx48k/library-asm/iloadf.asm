; __FASTCALL__ routine which
; loads a 40 bits floating point into A ED CB
; stored at position pointed by POINTER HL
;A DE, BC <-- ((HL))

__ILOADF:
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a

; __FASTCALL__ routine which
; loads a 40 bits floating point into A ED CB
; stored at position pointed by POINTER HL
;A DE, BC <-- (HL)

__LOADF:    ; Loads a 40 bits FP number from address pointed by HL
	ld a, (hl)	
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	ret

