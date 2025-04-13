	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
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
	ld hl, (_le - 1)
	sub h
	ccf
	sbc a, a
	neg
	ld (_l), a
	ld a, (_level)
	ld hl, (_le - 1)
	sub h
	ccf
	sbc a, a
	neg
	ld (_l), a
	ld a, (_le)
	push af
	ld a, (_level)
	pop hl
	sub h
	ccf
	sbc a, a
	neg
	ld (_l), a
	ld a, (_le)
	push af
	ld a, (_level)
	pop hl
	sub h
	ccf
	sbc a, a
	neg
	ld (_l), a
	ld a, (_level)
	or a
	ccf
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
