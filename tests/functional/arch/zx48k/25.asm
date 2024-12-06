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
	DEFB 00, 00, 00, 00
_c:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld de, 5
	ld hl, 6553
	ld (_a), hl
	ld (_a + 2), de
	ld hl, (_a)
	ld de, (_a + 2)
	call .core.__NOT32
	neg
	ld (_c), a
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bool/not32.asm"
	; -------------------------------------------------------------
	; 32 bit logical NOT
	; -------------------------------------------------------------
	    push namespace core
__NOT32:	; A = ¬A
	    ld a, d
	    or e
	    or h
	    or l
	    sub 1	; Gives CARRY only if 0
	    sbc a, a; Gives 0 if not carry, FF otherwise
	    ret
	    pop namespace
#line 26 "arch/zx48k/25.bas"
	END
