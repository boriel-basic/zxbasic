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
_toloX:
	DEFB 00, 00
_toloY:
	DEFB 00, 00
_doorX:
	DEFB 00
_doorY:
	DEFB 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld hl, (_toloX)
	ld a, (hl)
	cp 3
	sbc a, a
	ld d, a
	ld hl, (_toloX)
	ld a, 107
	cp (hl)
	sbc a, a
	or d
	ld d, a
	ld hl, (_toloY)
	ld a, (hl)
	cp 2
	sbc a, a
	or d
	ld d, a
	ld hl, (_toloY)
	ld a, 86
	cp (hl)
	sbc a, a
	or d
	push af
	ld hl, (_toloX)
	ld a, (hl)
	ld hl, (_doorX - 1)
	sub h
	sub 1
	sbc a, a
	push af
	ld hl, (_toloY)
	ld a, (hl)
	ld hl, (_doorY - 1)
	sub h
	sub 1
	sbc a, a
	ld h, a
	pop af
	or a
	jr z, __LABEL2
	ld a, h
__LABEL2:
	pop de
	or d
	push af
	ld hl, (_toloY)
	ld de, (_toloX)
	or a
	sbc hl, de
	pop de
	sbc a, a
	or d
	jp z, __LABEL1
	xor a
	ld (_doorX), a
__LABEL1:
	ld hl, 0
	ld b, h
	ld c, l
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
