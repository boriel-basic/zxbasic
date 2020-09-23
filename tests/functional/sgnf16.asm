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
_y:
	DEFB 00h
	DEFB 00h
	DEFB 01h
	DEFB 00h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_y)
	ld de, (_y + 2)
	call __SGNF16
	ld (0), a
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
#line 1 "sgnf16.asm"
#line 1 "sgn.asm"
	; Returns SGN (SIGN) for 32, 16 and 8 bits signed integers, Fixed and FLOAT
	    PROC
	    LOCAL __ENDSGN
__SGNF:
	    or b
	    or c
	    or d
	    or e
	    ret z
	    ld a, e
	    jr __ENDSGN
__SGNF16:
__SGNI32:
		ld a, h
		or l
		or e
		or d
		ret z
	    ld a, d
	    jr __ENDSGN
__SGNI16:
		ld a, h
		or l
		ret z
		ld a, h
__ENDSGN:
		or a
		ld a, 1
		ret p
		neg
		ret
	    ENDP
#line 2 "sgnf16.asm"
#line 22 "sgnf16.bas"
	END
