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
__LABEL__10:
__LABEL0:
__LABEL__20:
	jp __LABEL0
__LABEL1:
__LABEL2:
	jp __LABEL2
__LABEL3:
__LABEL__30:
__LABEL4:
__LABEL__40:
	ld hl, _a
	inc (hl)
__LABEL__50:
	jp __LABEL4
__LABEL5:
__LABEL6:
	ld hl, _a
	inc (hl)
	jp __LABEL6
__LABEL7:
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

ZXBASIC_USER_DATA:
_a:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
