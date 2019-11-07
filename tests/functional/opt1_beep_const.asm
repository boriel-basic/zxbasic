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
	ld hl, 1642
	push hl
	ld hl, 261
	call __BEEPER
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
#line 1 "beeper.asm"
; vim:ts=4:et:sw=4:
	; This is a fast beep routine, but needs parameters
	; codified in a different way.
; See http://www.wearmouth.demon.co.uk/zx82.htm#L03F8
	; Needs pitch on top of the stack
	; HL = duration
__BEEPER:
	    ex de, hl
	    pop hl
	    ex (sp), hl ; CALLEE
	    push ix     ; BEEPER changes IX
	    call 03B5h
	    pop ix
	    ret
#line 22 "opt1_beep_const.bas"
ZXBASIC_USER_DATA:
; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
