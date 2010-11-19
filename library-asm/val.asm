#include once <alloc.asm>
#include once <stackf.asm>
#include once <error.asm>

VAL: ; Computes VAL(a$) using ROM FP-CALC
	 ; HL = address of a$
	 ; Returns FP number in C ED LH registers
	 ; A Register = 1 => Free a$ on return
	
	PROC

	LOCAL STK_STO_S
	LOCAL __RET_ZERO
	LOCAL __RET_ZERO2
	LOCAL ERR_SP
	LOCAL STKBOT
	LOCAL RECLAIM1
	LOCAL __VAL_ERROR
	LOCAL __VAL_EMPTY

RECLAIM1	EQU 6629
STKBOT		EQU 23651
ERR_SP		EQU 23613
STK_STO_S	EQU	2AB2h

	push af
	ld a, h
	or l
	jr z, __RET_ZERO ; NULL STRING => Return 0 

	push hl	; Not null string. Save its address for later

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	ld a, b
	or c
	jr z, __VAL_EMPTY ; Jumps VAL_EMPTY on empty string

	ex de, hl ; DE = String start

	ld hl, (STKBOT)
	push hl

	ld hl, (ERR_SP)
	push hl

	ld hl, __VAL_ERROR
	push hl

	ld hl, 0
	add hl, sp
	ld (ERR_SP), hl

	call STK_STO_S ; Enter it on the stack

	ld b, 1Dh ; "VAL"
	rst 28h	; ROM CALC
	defb 1Dh ; VAL
	defb 38h ; END CALC

	pop hl 	; Discard current ERR_SP item
	pop hl
	ld (ERR_SP), hl	; Restores ERR_SP

	ld hl, (STKBOT)  ; current SKTBOT
	pop de	; old STKBOT
	call	RECLAIM1 ; Recover unused space

	pop hl 	; String pointer
	pop af	; Deletion flag
	or a
	call nz, __MEM_FREE	; Frees string content before returning

	jp __FPSTACK_POP	; Recovers result and return from there

__VAL_EMPTY:	; Jumps here on empty string
	pop hl
	pop af
	or a
	call nz, __MEM_FREE ; Frees "" string
	jr __RET_ZERO2

__VAL_ERROR:	; Jumps here on ERROR
	pop hl
	ld (ERR_SP), hl ; Restores ERR_SP

	ld hl, (STKBOT)  ; current SKTBOT
	pop de	; old STKBOT
	call	RECLAIM1 ; Recover unused space

	pop hl
	pop af
	or a
	call nz, __MEM_FREE

	ld a, ERROR_Ok
	ld (ERR_NR), a
	push af

__RET_ZERO:	; Returns 0 Floating point on error
	pop af

__RET_ZERO2:
	xor a
	ld b, a
	ld c, a
	ld d, b
	ld e, c
	ret

	ENDP

