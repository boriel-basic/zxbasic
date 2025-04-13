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
_sprite:
	DEFB 00
_lin:
	DEFB 00
_col:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
.LABEL.__LABEL0:
	xor a
	ld (_sprite), a
	jp .LABEL.__LABEL2
.LABEL.__LABEL5:
	ld a, (0)
	ld (_lin), a
	ld a, (1)
	ld (_col), a
	xor a
	ld (3), a
.LABEL.__LABEL6:
	ld hl, _sprite
	inc (hl)
.LABEL.__LABEL2:
	ld a, 7
	ld hl, (_sprite - 1)
	cp h
	jp nc, .LABEL.__LABEL5
.LABEL.__LABEL4:
	jp .LABEL.__LABEL0
.LABEL.__LABEL1:
.LABEL._btiles:
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
