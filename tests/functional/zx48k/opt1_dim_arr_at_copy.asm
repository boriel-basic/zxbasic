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
	_a.__DATA__ EQU 16384
_a:
	DEFW .LABEL.__LABEL0
_a.__DATA__.__PTR__:
	DEFW 16384
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 02h
_b:
	DEFW .LABEL.__LABEL1
_b.__DATA__.__PTR__:
	DEFW _b.__DATA__
_b.__DATA__:
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
	DEFB 00h
	DEFB 0FFh
.LABEL.__LABEL1:
	DEFW 0000h
	DEFB 02h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, 16
	ld b, h
	ld c, l
	ld hl, _b.__DATA__
	ld de, _a.__DATA__
	ldir
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
