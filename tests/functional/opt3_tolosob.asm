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
__LABEL__inicio:
	ld de, 0
	ld hl, (_toloTimer)
	or a
	sbc hl, de
	jp nz, __LABEL__inicio
	ld a, 1
	ld (_sobando), a
	sub 2
	jp nz, __LABEL3
	ld hl, (_toloTimer)
	inc hl
	ld a, (hl)
	sub 12
	jp nz, __LABEL5
	ld a, 3
	ld (_sobando), a
	jp __LABEL__inicio
__LABEL5:
__LABEL3:
	ld a, (_sobando)
	or a
	jp nz, __LABEL__inicio
	ld de, 10
	ld hl, (_toloTimer)
	or a
	sbc hl, de
	jp nz, __LABEL__inicio
	ld hl, (_toloStatus)
	ld a, (hl)
	and 2
	jp nz, __LABEL__inicio
	ld a, 1
	ld (_sobando), a
__LABEL__pontolosobando:
__LABEL11:
__LABEL9:
__LABEL7:
__LABEL1:
	jp __LABEL__inicio
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
__CALL_BACK__:
	DEFW 0
#line 1 "eq16.asm"

__EQ16:	; Test if 16bit values HL == DE
		; Returns result in A: 0 = False, FF = True
			xor a	; Reset carry flag
			sbc hl, de
			ret nz
			inc a
			ret

#line 55 "opt3_tolosob.bas"

ZXBASIC_USER_DATA:
_toloTimer:
	DEFB 00, 00
_toloStatus:
	DEFB 00, 00
_sobando:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
