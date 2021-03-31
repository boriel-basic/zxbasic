	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core.__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
#line 2 "haplo0asm.bas"
		tablaColor  equ 2
		tablaColorAlto equ tablaColor >> 8
		tablaColorBajo equ tablaColor & 0xFF
		tablaColorCheck equ (tablaColorAlto << 8) | tablaColorBajo
		tabla1  equ tablaColor + 1
		tabla2  equ tablaColor ^ 2
		tabla3  equ tablaColor % 3
		tabla4  equ tablaColor ~ 5
		ld a, tablaColorAlto
		ld b, tablaColorBajo
#line 14 "haplo0asm.bas"
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
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
