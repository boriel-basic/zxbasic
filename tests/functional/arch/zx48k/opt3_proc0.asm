	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	call _p
	ld bc, 0
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
_p:
#line 4 "arch/zx48k/opt3_proc0.bas"
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
#line 33 "arch/zx48k/opt3_proc0.bas"
_p__leave:
	ret
	;; --- end of user code ---
	END
