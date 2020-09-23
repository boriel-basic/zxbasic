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
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
#line 0
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
#line 10
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
	END
