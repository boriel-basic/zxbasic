	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
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
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
_test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
	ld a, (_test_a.__DATA__ + 13)
	ld (ix-1), a
	ld hl, _test_a.__DATA__
	ld de, 13
	add hl, de
	ld a, l
	ld (ix-1), a
_test__leave:
	ld sp, ix
	pop ix
	ret
ZXBASIC_USER_DATA:
_c:
	DEFB 00
	_a.__DATA__ EQU 20000
_a:
	DEFW __LABEL0
_a.__DATA__.__PTR__:
	DEFW 20000
__LABEL0:
	DEFW 0001h
	DEFW 0005h
	DEFB 01h
	_test_a.__DATA__ EQU 30000
_test_a:
	DEFW __LABEL1
_test_a.__DATA__.__PTR__:
	DEFW 30000
__LABEL1:
	DEFW 0001h
	DEFW 0005h
	DEFB 01h
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
