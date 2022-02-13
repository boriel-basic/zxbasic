	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
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
	call _main
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
_saludar:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+4)
	ld h, (ix+5)
	inc hl
_saludar__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_main:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld (ix-2), 0
	ld (ix-1), 0
.LABEL.__LABEL0:
	ld l, (ix-2)
	ld h, (ix-1)
	ld de, 2
	or a
	sbc hl, de
	jp nc, _main__leave
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	call _saludar
	ld l, (ix-2)
	ld h, (ix-1)
	inc hl
	ld (ix-2), l
	ld (ix-1), h
	jp .LABEL.__LABEL0
_main__leave:
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
	END
