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
_subeEgg:
	DEFB 00
_sail:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, (_sail)
	dec a
	jp nz, .LABEL.__LABEL1
	ld a, (_subeEgg)
	or a
	jp nz, .LABEL.__LABEL3
	ld a, (40011)
	ld hl, (40043 - 1)
	cp h
	jp nc, .LABEL.__LABEL5
	ld a, (40044)
	ld hl, (40012 - 1)
	sub h
	call .core.__ABS8
	push af
	ld h, 16
	pop af
	call .core.__LTI8
	or a
	jp z, .LABEL.__LABEL7
	ld a, (40011)
	ld hl, (40043 - 1)
	sub h
	call .core.__ABS8
	push af
	ld h, 20
	pop af
	call .core.__LTI8
	or a
	jp nz, .LABEL._enddispara
.LABEL.__LABEL9:
.LABEL.__LABEL7:
.LABEL.__LABEL5:
.LABEL.__LABEL3:
.LABEL.__LABEL1:
	jp .LABEL._enddispara
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
.LABEL._enddispara:
	ld hl, 0
	ld b, h
	ld c, l
	jp .core.__END_PROGRAM
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/abs8.asm"
	; Returns absolute value for 8 bit signed integer
	;
	    push namespace core
__ABS8:
	    or a
	    ret p
	    neg
	    ret
	    pop namespace
#line 55 "arch/zx48k/053opt.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti8.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lei8.asm"
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
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti8.asm"
#line 56 "arch/zx48k/053opt.bas"
	END
