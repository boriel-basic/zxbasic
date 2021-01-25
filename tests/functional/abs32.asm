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
_a:
	DEFB 00, 00, 00, 00
_b:
	DEFB 00, 00, 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_b)
	ld de, (_b + 2)
	call __ABS32
	ld (_a), hl
	ld (_a + 2), de
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/abs32.asm"
	; 16 bit signed integer abs value
	; HL = value
#line 1 "/zxbasic/src/arch/zx48k/library-asm/neg32.asm"
__ABS32:
		bit 7, d
		ret z
__NEG32: ; Negates DEHL (Two's complement)
		ld a, l
		cpl
		ld l, a
		ld a, h
		cpl
		ld h, a
		ld a, e
		cpl
		ld e, a
		ld a, d
		cpl
		ld d, a
		inc l
		ret nz
		inc h
		ret nz
		inc de
		ret
#line 5 "/zxbasic/src/arch/zx48k/library-asm/abs32.asm"
#line 22 "abs32.bas"
	END
