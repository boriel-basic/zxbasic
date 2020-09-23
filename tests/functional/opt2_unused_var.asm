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
	jp __MAIN_PROGRAM__
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	call _Check
	ld hl, 0
	call __PAUSE
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
__CALL_BACK__:
	DEFW 0
_TestPrint:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (0), a
	ld a, (ix+5)
	ld (0), a
_TestPrint__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_Check:
	push ix
	ld ix, 0
	add ix, sp
	ld a, 10
	push af
	ld a, 5
	push af
	call _TestPrint
	push bc
	push de
	push af
	ld a, 11
	push af
	ld a, 6
	push af
	call _TestPrint
	push bc
	push de
	push af
_Check__leave:
	ld sp, ix
	pop ix
	ret
#line 1 "pause.asm"
	; The PAUSE statement (Calling the ROM)
__PAUSE:
		ld b, h
	    ld c, l
	    jp 1F3Dh  ; PAUSE_1
#line 62 "opt2_unused_var.bas"
	END
