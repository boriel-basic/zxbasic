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
_myNumber:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	call .core.CLS
.LABEL._myBucle:
	xor a
	ld (_myNumber), a
	jp .LABEL.__LABEL0
.LABEL.__LABEL3:
	call _mySub
.LABEL.__LABEL4:
	ld hl, _myNumber
	inc (hl)
.LABEL.__LABEL0:
	ld a, 7
	ld hl, (_myNumber - 1)
	cp h
	jp nc, .LABEL.__LABEL3
.LABEL.__LABEL2:
	jp .LABEL._myBucle
_mySub:
	push ix
	ld ix, 0
	add ix, sp
_mySub__leave:
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/cls.asm"
	; JUMPS directly to spectrum CLS
	; This routine does not clear lower screen
	;CLS	EQU	0DAFh
	; Our faster implementation
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
	; Printing positioning library.
	    push namespace core
	    PROC
	    LOCAL ECHO_E
__LOAD_S_POSN:		; Loads into DE current ROW, COL print position from S_POSN mem var.
	    ld de, (S_POSN)
	    ld hl, (MAXX)
	    or a
	    sbc hl, de
	    ex de, hl
	    ret
__SAVE_S_POSN:		; Saves ROW, COL from DE into S_POSN mem var.
	    ld hl, (MAXX)
	    or a
	    sbc hl, de
	    ld (S_POSN), hl ; saves it again
	    ret
	ECHO_E	EQU 23682
	MAXX	EQU ECHO_E   ; Max X position + 1
	MAXY	EQU MAXX + 1 ; Max Y position + 1
	S_POSN	EQU 23688
	POSX	EQU S_POSN		; Current POS X
	POSY	EQU S_POSN + 1	; Current POS Y
	    ENDP
	    pop namespace
#line 9 "/zxbasic/src/arch/zx48k/library-asm/cls.asm"
	    push namespace core
CLS:
	    PROC
	    LOCAL COORDS
	    LOCAL __CLS_SCR
	    LOCAL ATTR_P
	    LOCAL SCREEN
	    ld hl, 0
	    ld (COORDS), hl
	    ld hl, 1821h
	    ld (S_POSN), hl
__CLS_SCR:
	    ld hl, SCREEN
	    ld (hl), 0
	    ld d, h
	    ld e, l
	    inc de
	    ld bc, 6144
	    ldir
	    ; Now clear attributes
	    ld a, (ATTR_P)
	    ld (hl), a
	    ld bc, 767
	    ldir
	    ret
	COORDS	EQU	23677
	SCREEN	EQU 16384 ; Default start of the screen (can be changed)
	ATTR_P	EQU 23693
	;you can poke (SCREEN_SCRADDR) to change CLS, DRAW & PRINTing address
	SCREEN_ADDR EQU (__CLS_SCR + 1) ; Address used by print and other screen routines
	    ; to get the start of the screen
	    ENDP
	    pop namespace
#line 28 "zx48k/warn_unreach0.bas"
	END
