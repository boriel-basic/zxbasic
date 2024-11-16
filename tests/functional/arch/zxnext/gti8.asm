	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 5
	ld hl, (_a - 1)
	call .core.__LTI8
	or a
	jp z, .LABEL.__LABEL1
	ld hl, _a
	inc (hl)
.LABEL.__LABEL1:
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
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/lti8.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/cmp/lei8.asm"
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
#line 2 "/zxbasic/src/lib/arch/zxnext/runtime/lti8.asm"
#line 21 "arch/zxnext/gti8.bas"
	END
