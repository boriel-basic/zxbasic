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
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_subeEgg:
	DEFB 00
_sail:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, (_sail)
	dec a
	jp nz, __LABEL__enddispara
	ld a, (_subeEgg)
	or a
	jp nz, __LABEL__enddispara
	ld a, (40011)
	ld hl, (40042)
	cp h
	jp nc, __LABEL__enddispara
	ld a, (40044)
	ld hl, (40011)
	sub h
	call __ABS8
	ld h, 16
	call __LTI8
	or a
	jp z, __LABEL__enddispara
	ld a, (40011)
	ld hl, (40042)
	sub h
	call __ABS8
	ld h, 20
	call __LTI8
__LABEL__enddispara:
	ld bc, 0
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
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
__ABS8:
		or a
		ret p
		neg
		ret
#line 40 "opt4_053opt.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lei8.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 41 "opt4_053opt.bas"
	END
