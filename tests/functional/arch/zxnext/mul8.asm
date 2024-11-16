	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
_a:
	DEFB 00
_b:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_a)
	xor a
	ld (_b), a
	ld a, (_a)
	ld (_b), a
	ld a, (_a)
	add a, a
	ld (_b), a
	ld a, (_a)
	add a, a
	add a, a
	ld (_b), a
	ld a, (_a)
	xor a
	ld (_b), a
	ld a, (_a)
	ld (_b), a
	ld a, (_a)
	add a, a
	ld (_b), a
	ld a, (_a)
	add a, a
	add a, a
	ld (_b), a
	ld hl, (_a - 1)
	ld a, (_a)
	ld d, h
	ld e, a
	mul d, e
	ld a, e
	ld (_b), a
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
	;; --- end of user code ---
	END
