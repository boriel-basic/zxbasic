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
_i:
	DEFB 00
_m:
	DEFB 00
_M:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
.LABEL._30:
	ld a, 1
	ld (_i), a
	jp .LABEL.__LABEL0
.LABEL.__LABEL3:
	ld a, 1
	ld (_m), a
	jp .LABEL.__LABEL5
.LABEL.__LABEL8:
.LABEL._40:
	xor a
	ld (_M), a
.LABEL.__LABEL9:
	ld hl, _m
	inc (hl)
.LABEL.__LABEL5:
	ld a, 6
	ld hl, (_m - 1)
	cp h
	jp nc, .LABEL.__LABEL8
.LABEL.__LABEL7:
.LABEL.__LABEL4:
	ld hl, _i
	inc (hl)
.LABEL.__LABEL0:
	ld a, 8
	ld hl, (_i - 1)
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
