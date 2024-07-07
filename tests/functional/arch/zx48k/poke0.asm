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
_i:
	DEFB 00h
	DEFB 40h
_j:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	xor a
	ld (_j), a
	jp .LABEL.__LABEL0
.LABEL.__LABEL3:
	ld a, 185
	ld hl, (_i)
	ld (hl), a
	ld hl, (_i)
	inc hl
	ld (_i), hl
.LABEL.__LABEL4:
	ld hl, _j
	inc (hl)
.LABEL.__LABEL0:
	ld a, 250
	ld hl, (_j - 1)
	cp h
	jp nc, .LABEL.__LABEL3
.LABEL.__LABEL2:
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
