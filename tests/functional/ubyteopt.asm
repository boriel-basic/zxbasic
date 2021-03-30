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
	core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core.__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld a, 2
	push af
	ld a, 1
	push af
	call _CanDraw
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
_CanDraw:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	push af
	ld h, 0
	pop af
	cp h
	sbc a, a
	push af
	ld a, (ix+5)
	push af
	ld h, 0
	pop af
	cp h
	sbc a, a
	pop de
	or d
	push af
	ld a, (ix+7)
	push af
	ld a, 20
	pop hl
	cp h
	sbc a, a
	pop de
	or d
	push af
	ld a, (ix+5)
	push af
	ld a, 31
	pop hl
	cp h
	sbc a, a
	pop de
	or d
	jp z, __LABEL1
	xor a
	jp _CanDraw__leave
__LABEL1:
	ld a, 1
_CanDraw__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
	END
