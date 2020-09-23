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
_a:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, (_a)
	ld l, a
	ld h, 0
	call USR
	ld a, l
	ld (_a), a
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
#line 1 "usr.asm"
	; Emulates the USR Sinclair BASIC function
	; Result value returns in BC
	; We use HL for returning values, su we must
	; copy BC into HL before returning
	;
	; The incoming parameter is HL (Address to JUMP)
	;
#line 1 "table_jump.asm"
JUMP_HL_PLUS_2A: ; Does JP (HL + A*2) Modifies DE. Modifies A
		add a, a
JUMP_HL_PLUS_A:	 ; Does JP (HL + A) Modifies DE
		ld e, a
		ld d, 0
JUMP_HL_PLUS_DE: ; Does JP (HL + DE)
		add hl, de
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl
CALL_HL:
		jp (hl)
#line 10 "usr.asm"
USR:
		call CALL_HL
		ld h, b
		ld l, c
		ret
#line 24 "opt1_usr.bas"
	END
