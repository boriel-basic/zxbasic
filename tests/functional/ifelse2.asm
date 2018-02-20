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
	ld h, 0
	ld a, (_i)
	call __LTI8
	or a
	jp z, __LABEL0
	ld hl, _i
	inc (hl)
	jp __LABEL1
__LABEL0:
	ld hl, _i
	dec (hl)
__LABEL1:
	ld h, 0
	ld a, (_i)
	call __LTI8
	or a
	jp z, __LABEL2
	ld hl, _i
	inc (hl)
	jp __LABEL3
__LABEL2:
	ld hl, _i
	dec (hl)
__LABEL3:
	ld hl, 0
	ld b, h
	ld c, l
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
#line 42 "ifelse2.bas"

ZXBASIC_USER_DATA:
_i:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
