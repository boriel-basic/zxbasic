#include once <free.asm>
#include once <stackf.asm>
#include once <error.asm>

VAL: ; Computes VAL(a$) using ROM FP-CALC
	 ; HL = address of a$
	 ; Returns FP number in C ED LH registers
	 ; A Register = 1 => Free a$ on return
	
	PROC

	LOCAL STK_STO_S
	LOCAL __RET_ZERO
	LOCAL ERR_SP
	LOCAL STKBOT
	LOCAL RECLAIM1
    LOCAL CH_ADD
	LOCAL __VAL_ERROR
	LOCAL __VAL_EMPTY
    LOCAL SET_MIN

RECLAIM1	EQU 6629
STKBOT		EQU 23651
ERR_SP		EQU 23613
CH_ADD      EQU 23645
STK_STO_S	EQU	2AB2h
SET_MIN     EQU 16B0h

    ld d, a ; Preserves A register in DE
	ld a, h
	or l
	jr z, __RET_ZERO ; NULL STRING => Return 0 

    push de ; Saves A Register (now in D)
	push hl	; Not null string. Save its address for later

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	ld a, b
	or c
	jr z, __VAL_EMPTY ; Jumps VAL_EMPTY on empty string

	ex de, hl ; DE = String start

    ld hl, (CH_ADD)
    push hl

	ld hl, (STKBOT)
	push hl

	ld hl, (ERR_SP)
	push hl

    ;; Now put our error handler on ERR_SP
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

	pop hl 	; Discards our current error handler
	pop hl
	ld (ERR_SP), hl	; Restores ERR_SP

	pop de	         ; old STKBOT
	ld hl, (STKBOT)  ; current SKTBOT
	call	RECLAIM1 ; Recover unused space

    pop hl  ; Discards old CH_ADD value
	pop hl 	; String pointer
	pop af	; Deletion flag
	or a
	call nz, __MEM_FREE	; Frees string content before returning

    ld a, ERROR_Ok      ; Sets OK in the result
    ld (ERR_NR), a

	jp __FPSTACK_POP	; Recovers result and return from there

__VAL_ERROR:	; Jumps here on ERROR
	pop hl
	ld (ERR_SP), hl ; Restores ERR_SP

	ld hl, (STKBOT)  ; current SKTBOT
	pop de	; old STKBOT
    pop hl
    ld (CH_ADD), hl  ; Recovers old CH_ADD

    call 16B0h       ; Resets temporary areas after an error

__VAL_EMPTY:	; Jumps here on empty string
	pop hl      ; Recovers initial string address
	pop af      ; String flag: If not 0 => it's temporary
	or a
	call nz, __MEM_FREE ; Frees "" string

__RET_ZERO:	; Returns 0 Floating point on error
	ld a, ERROR_Ok
	ld (ERR_NR), a

	xor a
	ld b, a
	ld c, a
	ld d, b
	ld e, c
	ret

	ENDP

