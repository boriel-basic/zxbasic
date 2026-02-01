	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
_y:
	DEFB 01h
	DEFB 00h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_y)
	call .core.__SGNU16
	ld (0), a
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/sgnu16.asm"
	; ----------------------------------------------------------------
	; This file is released under the MIT License
	;
	; Copyleft (k) 2008
; by Jose Rodriguez-Rosa (a.k.a. Boriel) <https://www.boriel.com>
	; ----------------------------------------------------------------
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/sgnu16.asm"
	; Returns SGN (SIGN) for 16 bits unsigned integer
	    push namespace core
__SGNU16:
	    ld a, h
	    or l
	    ret z
	    ld a, 1
	    ret
	    pop namespace
#line 9 "/zxbasic/src/lib/arch/zxnext/runtime/sgnu16.asm"
#line 16 "arch/zxnext/sgnu16.bas"
	END
