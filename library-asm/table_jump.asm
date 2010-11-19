
JUMP_HL_PLUS_2A: ; Does JP (HL + A*2) Modifies DE. Modifies A
	add a, a

JUMP_HL_PLUS_A:	 ; Does JP (HL + A) Modifies DE
	ld e, a
	ld d, 0

JUMP_HL_PLUS_DE: ; Does JP (HL + DE)
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
CALL_HL:
	jp (hl)

