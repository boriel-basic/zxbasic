	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
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
	ld hl, 1642
	push hl
	ld hl, 261
	call .core.__BEEPER
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/io/sound/beeper.asm"
; vim:ts=4:et:sw=4:
	; This is a fast beep routine, but needs parameters
	; codified in a different way.
; See http://www.wearmouth.demon.co.uk/zx82.htm#L03F8
	; Needs pitch on top of the stack
	; HL = duration
	    push namespace core
__BEEPER:
	    ex de, hl
	    pop hl
	    ex (sp), hl ; CALLEE
	    push ix     ; BEEPER changes IX
	    call 03B5h
	    pop ix
	    ret
	    pop namespace
#line 21 "arch/zx48k/opt1_beep_const.bas"
	END
