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
_t:
	DEFB 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_t + 2)
	push hl
	ld hl, (_t)
	push hl
	ld de, 0
	ld hl, 0
	call .core.__EQ32
	sub 1
	sbc a, a
	neg
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
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/eq32.asm"
	    push namespace core
__EQ32:	; Test if 32bit value HLDE equals top of the stack
    ; Returns result in A: 0 = False, FF = True
	    exx
	    pop bc ; Return address
	    exx
	    xor a	; Reset carry flag
	    pop bc
	    sbc hl, bc ; Low part
	    ex de, hl
	    pop bc
	    sbc hl, bc ; High part
	    exx
	    push bc ; CALLEE
	    exx
	    ld a, h
	    or l
	    or d
	    or e   ; a = 0 and Z flag set only if HLDE = 0
	    ld a, 1
	    ret z
	    xor a
	    ret
	    pop namespace
#line 28 "arch/zx48k/nei32.bas"
	END
