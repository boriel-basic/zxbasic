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
_myArray2:
	DEFW .LABEL.__LABEL0
_myArray2.__DATA__.__PTR__:
	DEFW _myArray2.__DATA__
	DEFW _myArray2.__LBOUND__
	DEFW 0
_myArray2.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 01h
_myArray2.__LBOUND__:
	DEFW 0001h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	call _Init
	ld hl, 0
	ld b, h
	ld c, l
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
_Init:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
_Init__leave:
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
	END
