	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core..__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core..__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_x:
	DEFB 00, 00, 00, 00
_dx:
	DEFB 00, 00, 00, 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld hl, (_x)
	ld de, (_x + 2)
	ld bc, (_dx)
	add hl, bc
	ex de, hl
	ld bc, (_dx + 2)
	adc hl, bc
	ex de, hl
	ld (_x), hl
	ld (_x + 2), de
	ex de, hl
	xor a
	ld (hl), a
	ld bc, 0
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
	;; --- end of user code ---
	END
