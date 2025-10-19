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
	DEFW 0
	DEFW 0
_a.__DATA__:
	DEFB 01h
	DEFB 02h
	DEFB 03h
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, _a.__DATA__
	inc hl
	push hl
	call _Incr
	ld a, (_a.__DATA__ + 1)
	ld (0), a
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
_Incr:
	push ix
	ld ix, 0
	add ix, sp
	ld h, (ix+5)
	ld l, (ix+4)
	ld a, (hl)
	inc a
	ld h, (ix+5)
	ld l, (ix+4)
	ld (hl), a
_Incr__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
	END
