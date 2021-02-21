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
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_a)
	ld de, (_a + 2)
	call __BNOT32
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/bnot32.asm"
; vim:ts=4:et:
	; FASTCALL bitwise or 32 version.
	; result in DE,HL
; __FASTCALL__ version (operands: A, H)
	; Performs 32bit NEGATION (cpl)
; Input: DE,HL
; Output: DE,HL <- NOT DE,HL
__BNOT32:
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
	    ret
#line 22 "bnot32.bas"
	END
