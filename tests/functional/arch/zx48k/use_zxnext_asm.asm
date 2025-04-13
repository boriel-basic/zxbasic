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
#line 2 "arch/zx48k/use_zxnext_asm.bas"
		LDIX
		LDWS
		LDIRX
		LDDX
		LDDRX
		LDPIRX
		OUTINB
		MUL D,E
		ADD HL,A
		ADD DE,A
		ADD BC,A
		ADD HL,0201h
		ADD DE,0201h
		ADD BC,0201h
		SWAPNIB
		MIRROR
		PUSH 4321h
		NEXTREG 37h,38h
		NEXTREG 33h,A
		PIXELDN
		PIXELAD
		SETAE
		TEST 77h
		BSLA DE,B
		BSRA DE,B
		BSRL DE,B
		BSRF DE,B
		BRLC DE,B
		JP (C)
#line 33 "arch/zx48k/use_zxnext_asm.bas"
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
	END
