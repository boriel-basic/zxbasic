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
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	call _p
	ld bc, 0
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
_p:
#line 5 "opt3_proc0.bas"
		PROC
		CP 22
		JR NZ, isNewline
		LOCAL isAt
isAt:
		EX DE,HL
		LD HL, -2
		ADD HL, BC
		EX DE,HL
		INC HL
		LD D,(HL)
		DEC BC
		INC HL
		LD E,(HL)
		DEC BC
		LOCAL isNewline
isNewline:
		ENDP
#line 33 "opt3_proc0.bas"
_p__leave:
	ret
	;; --- end of user code ---
	END
