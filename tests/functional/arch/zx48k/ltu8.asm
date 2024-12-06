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
	DEFB 01h
_le:
	DEFB 00h
_l:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_level)
	ld h, a
	ld a, (_le)
	cp h
	sbc a, a
	neg
	ld (_l), a
	ld hl, (_level - 1)
	ld a, (_le)
	cp h
	sbc a, a
	neg
	ld (_l), a
	ld a, (_le)
	push af
	ld hl, (_level - 1)
	pop af
	cp h
	sbc a, a
	neg
	ld (_l), a
	ld a, (_le)
	ld hl, (_level - 1)
	cp h
	sbc a, a
	neg
	ld (_l), a
	ld a, (_level)
	ld h, a
	xor a
	cp h
	sbc a, a
	neg
	ld (_l), a
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
