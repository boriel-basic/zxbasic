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
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_y:
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_y)
	ld de, (_y + 2)
	call __SGNU32
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
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sgnu32.asm"
	; Returns SGN (SIGN) for 32 bits unsigned integer
__SGNU32:
		ld a, h
		or l
		or d
		or e
		ret z
		ld a, 1
		ret
#line 21 "sgnu32.bas"
	END
