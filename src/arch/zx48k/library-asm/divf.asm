#include once <stackf.asm>
#include once <error.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses C EDHL registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order BC DE HL (B not used).
;
; Uses CALLEE convention
; -------------------------------------------------------------

__DIVF:	; Division
	PROC
	LOCAL __DIVBYZERO
	LOCAL TMP, ERR_SP

TMP         EQU 23629 ;(DEST)
ERR_SP      EQU 23613

	call __FPSTACK_PUSH2

	ld hl, (ERR_SP)
	ld (TMP), hl
	ld hl, __DIVBYZERO
	push hl
	ld hl, 0
	add hl, sp
	ld (ERR_SP), hl
	
	; ------------- ROM DIV
	rst 28h
	defb 01h	; EXCHANGE
	defb 05h	; DIV
	defb 38h;   ; END CALC

	pop hl
	ld hl, (TMP)
	ld (ERR_SP), hl

	jp __FPSTACK_POP

__DIVBYZERO:
	ld hl, (TMP)
	ld (ERR_SP), hl

	ld a, ERROR_NumberTooBig
	ld (ERR_NR), a

	; Returns 0 on DIV BY ZERO error
	xor a
	ld b, a
	ld c, a
	ld d, a
	ld e, a
	ret

	ENDP

