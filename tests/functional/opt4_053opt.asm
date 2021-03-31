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
_subeEgg:
	DEFB 00
_sail:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_sail)
	dec a
	jp nz, .LABEL.__LABEL__enddispara
	ld a, (_subeEgg)
	or a
	jp nz, .LABEL.__LABEL__enddispara
	ld a, (40011)
	ld hl, (40042)
	cp h
	jp nc, .LABEL.__LABEL__enddispara
	ld a, (40044)
	ld hl, (40011)
	sub h
	call .core.__ABS8
	ld h, 16
	call .core.__LTI8
	or a
	jp z, .LABEL.__LABEL__enddispara
	ld a, (40011)
	ld hl, (40042)
	sub h
	call .core.__ABS8
	ld h, 20
	call .core.__LTI8
.LABEL.__LABEL__enddispara:
	ld bc, 0
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
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/abs8.asm"
	; Returns absolute value for 8 bit signed integer
	;
	    push namespace core
__ABS8:
	    or a
	    ret p
	    neg
	    ret
	    pop namespace
#line 40 "opt4_053opt.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lei8.asm"
	    push namespace core
__LEI8: ; Signed <= comparison for 8bit int
	    ; A <= H (registers)
	    PROC
	    LOCAL checkParity
	    sub h
	    jr nz, __LTI
	    inc a
	    ret
__LTI8:  ; Test 8 bit values A < H
	    sub h
__LTI:   ; Generic signed comparison
	    jp po, checkParity
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 41 "opt4_053opt.bas"
	END
