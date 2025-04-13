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
_b:
	DEFB 00
_d1:
	DEFB 00
_d2:
	DEFB 00
_d3:
	DEFB 00
_f:
	DEFB 00
_VOFFS48K:
	DEFB 00
_VOFFS128K:
	DEFB 00
_VOFFSPEN:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_VOFFS48K)
	ld hl, (_b - 1)
	sub h
	ld (_d1), a
	ld a, (_VOFFS128K)
	ld hl, (_b - 1)
	sub h
	ld (_d2), a
	ld a, (_VOFFSPEN)
	ld hl, (_b - 1)
	sub h
	ld (_d3), a
	ld a, (_d1)
	ld (0), a
	ld a, (_d2)
	ld (1), a
	ld a, (_d3)
	ld (2), a
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
