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
_x:
	DEFB 00, 00, 00, 00
_y:
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_y)
	inc hl
	push hl
	ld bc, (_x)
	ld de, (_x + 2)
	pop hl
	call __STORE32
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/store32.asm"
__PISTORE32:
			push hl
			push ix
			pop hl
			add hl, bc
			pop bc
__ISTORE32:  ; Load address at hl, and stores E,D,B,C integer at that address
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
__STORE32:	; Stores the given integer in DEBC at address HL
			ld (hl), c
			inc hl
			ld (hl), b
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret
#line 24 "poke7.bas"
	END
