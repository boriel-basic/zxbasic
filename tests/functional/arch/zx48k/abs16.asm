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
_a:
	DEFB 00, 00
_b:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_b)
	call .core.__ABS16
	ld (_a), hl
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/abs16.asm"
	; 16 bit signed integer abs value
	; HL = value
#line 1 "/zxbasic/src/arch/zx48k/library-asm/neg16.asm"
	; Negates HL value (16 bit)
	    push namespace core
__ABS16:
	    bit 7, h
	    ret z
__NEGHL:
	    ld a, l			; HL = -HL
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    inc hl
	    ret
	    pop namespace
#line 5 "/zxbasic/src/arch/zx48k/library-asm/abs16.asm"
#line 20 "abs16.bas"
	END
