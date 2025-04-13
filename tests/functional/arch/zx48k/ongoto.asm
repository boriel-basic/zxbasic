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
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, .LABEL.__LABEL0
	push hl
	ld a, (_a)
	inc a
	call .core.__ON_GOTO
.LABEL._10:
	ld a, 10
	ld (0), a
.LABEL._20:
	ld a, 20
	ld (0), a
.LABEL._30:
	ld a, 30
	ld (0), a
	ld a, 99
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
.LABEL.__LABEL0:
	DEFB 3
	DEFW .LABEL._10
	DEFW .LABEL._20
	DEFW .LABEL._30
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/ongoto.asm"
	; ------------------------------------------------------
	; Implements ON .. GOTO
	; ------------------------------------------------------
	    push namespace core
__ON_GOSUB:
	    pop hl
	    ex (sp), hl  ; hl = beginning of table
	    call __ON_GOTO_START
	    ret
__ON_GOTO:
	    pop hl
	    ex (sp), hl  ; hl = beginning of table
__ON_GOTO_START:
	    ; hl = address of jump table
	    ; a = index (0..255)
	    cp (hl) ; length of last post
	    ret nc  ; a >= length of last position (out of range)
	    inc hl
	    pop de  ; removes ret addr from the stack
	    ld d, 0
	    add a, a
	    ld e, a
	    rl d
	    add hl, de
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    jp (hl)
	    pop namespace
#line 38 "arch/zx48k/ongoto.bas"
	END
