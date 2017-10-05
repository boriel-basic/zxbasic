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
	ld a, 1
	ld (_b), a
	ld hl, __LBOUND__._a
	push hl
	ld a, (_b)
	ld l, a
	ld h, 0
	call __BOUND
	ld (_c), hl
	ld hl, __LBOUND__._a
	push hl
	ld a, (_b)
	inc a
	ld l, a
	ld h, 0
	call __BOUND
	ld (_c), hl
	ld hl, __LBOUND__._a
	push hl
	ld a, (_b)
	dec a
	ld l, a
	ld h, 0
	call __BOUND
	ld (_c), hl
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
#line 1 "bound.asm"

	; ---------------------------------------------------------
	; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com
	;
; ZX BASIC Compiler http://www.zxbasic.net
	; This code is released under the BSD License
	; ---------------------------------------------------------

	; Implements bothe the LBOUND(array, N) and RBOUND(array, N) function

; Parameters:
	;   HL = N (dimension)
	;   [stack - 2] -> LBound table for the var
	;   Returns entry [N] in HL

__BOUND:
	    add hl, hl      ; hl *= 2
	    ex de, hl
	    pop hl
	    ex (sp), hl     ; __CALLEE

	    add hl, de      ; hl += OFFSET __LBOUND._xxxx
	    ld e, (hl)      ; de = (hl)
	    inc hl
	    ld d, (hl)

	    ex de, hl       ; hl = de => returns result in HL
	    ret

#line 43 "bound02.bas"

ZXBASIC_USER_DATA:
_b:
	DEFB 00
_c:
	DEFB 00, 00
_a:
	DEFW 0001h
	DEFW 0004h
	DEFB 02h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
__LBOUND__._a:
	DEFW 0002h
	DEFW 0002h
	DEFW 0003h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
