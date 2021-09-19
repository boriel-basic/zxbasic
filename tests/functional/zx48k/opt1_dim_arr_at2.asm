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
_c:
	DEFB 00
	_a.__DATA__ EQU 20000
_a:
	DEFW .LABEL.__LABEL0
_a.__DATA__.__PTR__:
	DEFW 20000
.LABEL.__LABEL0:
	DEFW 0001h
	DEFW 0005h
	DEFB 01h
	_test.a.__DATA__ EQU 30000
_test.a:
	DEFW .LABEL.__LABEL1
_test.a.__DATA__.__PTR__:
	DEFW 30000
.LABEL.__LABEL1:
	DEFW 0001h
	DEFW 0005h
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_a.__DATA__ + 13)
	ld (_c), a
	ld hl, _a.__DATA__
	ld de, 13
	add hl, de
	ld a, l
	ld (_c), a
	call _test
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
_test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
	ld a, (_test.a.__DATA__ + 13)
	ld (ix-1), a
	ld hl, _test.a.__DATA__
	ld de, 13
	add hl, de
	ld a, l
	ld (ix-1), a
_test__leave:
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
	END
