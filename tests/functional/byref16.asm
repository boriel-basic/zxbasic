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
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
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
_test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld hl, 0
	ld bc, 4
	call __PISTORE16
	ld l, (ix-2)
	ld h, (ix-1)
	ld bc, 4
	call __PISTORE16
	ld hl, (_y)
	ld bc, 4
	call __PISTORE16
	ld h, (ix+5)
	ld l, (ix+4)
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	ld (_y), hl
_test__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/istore16.asm"
__PISTORE16: ; stores an integer in hl into address IX + BC; Destroys DE
			ex de, hl
			push ix
			pop hl
			add hl, bc
__ISTORE16:  ; Load address at hl, and stores E,D integer at that address
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			ld (hl), e
			inc hl
			ld (hl), d
			ret
#line 48 "byref16.bas"
	END
