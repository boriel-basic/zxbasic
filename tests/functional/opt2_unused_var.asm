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
	call _Check
	ld hl, 0
	call .core.__PAUSE
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
_TestPrint:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (0), a
	ld a, (ix+5)
	ld (0), a
_TestPrint__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_Check:
	ld a, 10
	push af
	ld a, 5
	push af
	call _TestPrint
	ld a, 11
	push af
	ld a, 6
	push af
	call _TestPrint
_Check__leave:
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/pause.asm"
	; The PAUSE statement (Calling the ROM)
	    push namespace core
__PAUSE:
	    ld b, h
	    ld c, l
	    jp 1F3Dh  ; PAUSE_1
	    pop namespace
#line 50 "opt2_unused_var.bas"
	END
