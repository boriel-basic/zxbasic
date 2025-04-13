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
_level:
	DEFB 00h
	DEFB 00h
_le:
	DEFB 01h
	DEFB 00h
_l:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_level)
	ld de, (_le)
	call .core.__LEI16
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, (_level)
	ld de, (_le)
	call .core.__LEI16
	ld l, a
	ld h, 0
	ld (_l), hl
	ld de, (_le)
	ld hl, (_level)
	call .core.__LEI16
	ld l, a
	ld h, 0
	ld (_l), hl
	ld de, (_le)
	ld hl, (_level)
	call .core.__LEI16
	ld l, a
	ld h, 0
	ld (_l), hl
	ld hl, (_level)
	ld de, 1
	call .core.__LEI16
	ld l, a
	ld h, 0
	ld (_l), hl
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
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/cmp/lei16.asm"
	    push namespace core
__LEI16:
	    PROC
	    LOCAL checkParity
	    or a
	    sbc hl, de
	    ld a, 1
	    ret z
	    jp po, checkParity
	    ld a, h
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 43 "arch/zxnext/gei16.bas"
	END
