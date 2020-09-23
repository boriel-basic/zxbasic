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
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_a:
	DEFB 00, 00, 00, 00
_b:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 0
	call __OR32
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld de, 0
	ld hl, 1
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 0
	push bc
	call __OR32
	ld (_b), a
	ld hl, (_a)
	ld de, (_a + 2)
	ld bc, 0
	push bc
	ld bc, 1
	push bc
	call __OR32
	ld (_b), a
	ld hl, (_a + 2)
	push hl
	ld hl, (_a)
	push hl
	ld hl, (_a)
	ld de, (_a + 2)
	call __OR32
	ld (_b), a
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
#line 1 "or32.asm"
__OR32:  ; Performs logical operation A AND B
	         ; between DEHL and TOP of the stack.
	         ; Returns A = 0 (False) or A = FF (True)
	    ld a, h
	    or l
	    or d
	    or e
	    pop hl ; Return address
	    pop de
	    ex (sp), hl
	    or d
	    or e
	    or h
	    or l
#line 24 "/zxbasic/arch/zx48k/library-asm/or32.asm"
	    ret
#line 58 "or32.bas"
	END
