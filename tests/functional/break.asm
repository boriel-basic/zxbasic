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
_a:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
.LABEL._10:
		push hl
	ld hl, 4
	call .core.CHECK_BREAK
.LABEL._20:
	ld a, 1
	ld (_a), a
		push hl
	ld hl, 5
	call .core.CHECK_BREAK
.LABEL._30:
	ld a, 2
	ld (_a), a
	inc a
	ld (_a), a
		push hl
	ld hl, 6
	call .core.CHECK_BREAK
	ld a, 40
	ld (_a), a
		push hl
	ld hl, 10
	call .core.CHECK_BREAK
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
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/break.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/error.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/break.asm"
	; Check if BREAK is pressed
	; Return if not. Else Raises
	; L BREAK Into Program Error
	; HL contains the line number we want to appear in the error msg.
	    push namespace core
CHECK_BREAK:
	    PROC
	    LOCAL PPC, TS_BRK, NO_BREAK
	    push af
	    call TS_BRK
	    jr c, NO_BREAK
	    ld (PPC), hl ; line num
	    ld a, ERROR_BreakIntoProgram
	    jp __ERROR   ; this stops the program and exits to BASIC
NO_BREAK:
	    pop af
	    pop hl       ; ret address
	    ex (sp), hl  ; puts it back into the stack and recovers initial HL
	    ret
	PPC EQU 23621
	TS_BRK EQU 8020
	    ENDP
	    pop namespace
#line 40 "break.bas"
	END
