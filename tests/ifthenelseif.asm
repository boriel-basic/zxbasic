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
__LABEL__5:
__LABEL__10:
	ld a, (_a)
	dec a
	add a, a
	jp nc, __LABEL0
	ld a, (_a)
	inc a
	ld (_a), a
	jp __LABEL1
__LABEL0:
__LABEL__20:
	ld a, (_a)
	push af
	xor a
	pop hl
	sub h
	add a, a
	jp nc, __LABEL3
	xor a
	ld (_a), a
__LABEL__30:
__LABEL3:
__LABEL1:
__LABEL__40:
	ld a, (_a)
	dec a
	add a, a
	jp nc, __LABEL4
	ld a, (_a)
	inc a
	ld (_a), a
	jp __LABEL5
__LABEL4:
__LABEL__50:
	ld a, (_a)
	push af
	xor a
	pop hl
	sub h
	add a, a
	jp nc, __LABEL6
	xor a
	ld (_a), a
	jp __LABEL7
__LABEL6:
	ld a, (_a)
	sub 1
	jp nc, __LABEL9
	ld a, 255
	ld (_a), a
__LABEL__60:
__LABEL9:
__LABEL7:
__LABEL5:
	ld a, (_a)
	dec a
	add a, a
	jp nc, __LABEL10
	ld a, (_a)
	inc a
	ld (_a), a
	jp __LABEL11
__LABEL10:
	ld a, (_a)
	push af
	xor a
	pop hl
	sub h
	add a, a
	jp nc, __LABEL13
	xor a
	ld (_a), a
__LABEL13:
__LABEL11:
	ld a, (_a)
	dec a
	add a, a
	jp nc, __LABEL14
	ld a, (_a)
	inc a
	ld (_a), a
	jp __LABEL15
__LABEL14:
	ld a, (_a)
	push af
	xor a
	pop hl
	sub h
	add a, a
	jp nc, __LABEL16
	xor a
	ld (_a), a
	jp __LABEL17
__LABEL16:
	ld a, (_a)
	sub 1
	jp nc, __LABEL19
	ld a, 255
	ld (_a), a
__LABEL19:
__LABEL17:
__LABEL15:
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
