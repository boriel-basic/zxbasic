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
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 5
	call __EQ32
	or a
	jp z, __LABEL1
	ld de, 0
	ld hl, 1
	ld bc, (_a)
	add hl, bc
	ex de, hl
	ld bc, (_a + 2)
	adc hl, bc
	ex de, hl
	ld (_a), hl
	ld (_a + 2), de
__LABEL1:
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/eq32.asm"
__EQ32:	; Test if 32bit value HLDE equals top of the stack
		; Returns result in A: 0 = False, FF = True
			exx
			pop bc ; Return address
			exx
			xor a	; Reset carry flag
			pop bc
			sbc hl, bc ; Low part
			ex de, hl
			pop bc
			sbc hl, bc ; High part
			exx
			push bc ; CALLEE
			exx
			ld a, h
			or l
			or d
			or e   ; a = 0 and Z flag set only if HLDE = 0
			ld a, 1
			ret z
			xor a
			ret
#line 37 "equ32.bas"
	END
