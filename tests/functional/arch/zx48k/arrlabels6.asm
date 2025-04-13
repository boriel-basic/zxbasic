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
_a:
	DEFW .LABEL.__LABEL0
_a.__DATA__.__PTR__:
	DEFW _a.__DATA__
	DEFW _a.__LBOUND__
	DEFW 0
_a.__DATA__:
	DEFW .LABEL._label1
	DEFW .LABEL._label2
	DEFW .LABEL._label3
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 02h
_a.__LBOUND__:
	DEFW 0001h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_a.__DATA__ + 0)
	push hl
	ld a, 5
	pop hl
	ld (hl), a
.LABEL._label1:
.LABEL._label2:
.LABEL._label3:
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
