	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
_EvalBASIC:
#line 49 "/zxbasic/src/lib/arch/zx48k/stdlib/basic.bas"
		push namespace core
		PROC
		LOCAL E_LINE
		LOCAL CH_ADD
		LOCAL SET_MIN
		LOCAL MAKE_ROOM
		LOCAL K_CUR
		LOCAL LINE_SCAN
		LOCAL LINE_RUN
		LOCAL DEF_ADD
		LOCAL NEWPPC
		LOCAL NSPPC
		LOCAL PPC
		LOCAL SUBPPC
		LOCAL NXTLIN
		E_LINE            equ 5c59h
		CH_ADD            equ 5c5dh
		SET_MIN           equ 16b0h
		MAKE_ROOM         equ 1655h
		K_CUR             equ 5c5bh
		LINE_SCAN         equ 1b17h
		LINE_RUN          equ 1b8ah
		DEF_ADD           equ 5c0bh
		NEWPPC            equ 5c42h
		NSPPC             equ 5c44h
		PPC               equ 5c45h
		SUBPPC            equ 5c47h
		NXTLIN            equ 5c55h
		ld a, h
		or l
		ret z
		ld de,(CH_ADD)
		push de
		ld de,(NXTLIN)
		push de
		ld de,(PPC)
		push de
		ld a,(SUBPPC)
		push af
		ld de,(NEWPPC)
		push de
		ld a,(NSPPC)
		push af
		push ix
		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl
		push hl
		push bc
		call SET_MIN
		ld hl,(E_LINE)
		pop bc
		push bc
		call MAKE_ROOM
		pop bc
		pop hl
		ld de,(E_LINE)
		ldir
		ld (K_CUR),de
		call LINE_SCAN
		bit 7,(iy+0)
		ld a, ERROR_NonsenseInBasic
		jp z, __ERROR
		ld hl,(E_LINE)
		ld (CH_ADD),hl
		set 7,(iy+1)
		ld (iy+0),0xff
		ld (iy+10),1
		call LINE_RUN
		pop ix
		pop af
		ld (NSPPC),a
		pop hl
		ld (NEWPPC),hl
		pop af
		ld (SUBPPC),a
		pop hl
		ld (PPC),hl
		pop hl
		ld (NXTLIN),hl
		pop hl
		ld (CH_ADD),hl
		ENDP
		pop namespace
#line 143 "/zxbasic/src/lib/arch/zx48k/stdlib/basic.bas"
_EvalBASIC__leave:
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
	ERR_NR    EQU    23610    ; Error code system variable
	; Error code definitions (as in ZX spectrum manual)
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
	    pop namespace
#line 148 "/zxbasic/src/lib/arch/zx48k/stdlib/basic.bas"
	END
