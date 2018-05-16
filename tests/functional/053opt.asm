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
	ld a, (_sail)
	dec a
	jp nz, __LABEL1
	ld a, (_subeEgg)
	or a
	jp nz, __LABEL3
	ld a, (40011)
	ld hl, (40043 - 1)
	cp h
	jp nc, __LABEL5
	ld a, (40044)
	ld hl, (40012 - 1)
	sub h
	call __ABS8
	push af
	ld h, 16
	pop af
	call __LTI8
	or a
	jp z, __LABEL7
	ld a, (40011)
	ld hl, (40043 - 1)
	sub h
	call __ABS8
	push af
	ld h, 20
	pop af
	call __LTI8
	or a
	jp nz, __LABEL__enddispara
__LABEL9:
__LABEL7:
__LABEL5:
__LABEL3:
__LABEL1:
	jp __LABEL__enddispara
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
__LABEL__enddispara:
	ld hl, 0
	ld b, h
	ld c, l
	jp __END_PROGRAM
#line 1 "abs8.asm"

	; Returns absolute value for 8 bit signed integer
	;
__ABS8:
		or a
		ret p
		neg
		ret

#line 56 "053opt.bas"
#line 1 "lti8.asm"

#line 1 "lei8.asm"

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
#line 2 "lti8.asm"
#line 57 "053opt.bas"

ZXBASIC_USER_DATA:
_subeEgg:
	DEFB 00
_sail:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
