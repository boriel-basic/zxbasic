	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_level:
	DEFB 00h
	DEFB 00h
_le:
	DEFB 01h
	DEFB 00h
_l:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_level)
	ex de, hl
	ld hl, (_le)
	or a
	sbc hl, de
	ccf
	sbc a, a
	neg
	ld l, a
	ld h, 0
	ld (_l), hl
	ld de, (_level)
	ld hl, (_le)
	or a
	sbc hl, de
	ccf
	sbc a, a
	neg
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, (_le)
	push hl
	ld de, (_level)
	pop hl
	or a
	sbc hl, de
	ccf
	sbc a, a
	neg
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	ccf
	sbc a, a
	neg
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, (_level)
	ex de, hl
	ld hl, 1
	or a
	sbc hl, de
	ccf
	sbc a, a
	neg
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
	END
