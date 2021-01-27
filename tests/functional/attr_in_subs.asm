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
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	call _screenAttributes2
	call CLS
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
_screenAttributes2:
	push ix
	ld ix, 0
	add ix, sp
	ld a, 4
	call PAPER
	ld a, 1
	call BRIGHT
	ld a, 2
	call INK
	call COPY_ATTR
_screenAttributes2__leave:
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/bright.asm"
	; Sets bright flag in ATTR_P permanently
; Parameter: Paper color in A register
#line 1 "/zxbasic/src/arch/zx48k/library-asm/const.asm"
	; Global constants
	P_FLAG	EQU 23697
	FLAGS2	EQU 23681
	ATTR_P	EQU 23693	; permanet ATTRIBUTES
	ATTR_T	EQU 23695	; temporary ATTRIBUTES
	CHARS	EQU 23606 ; Pointer to ROM/RAM Charset
	UDG	EQU 23675 ; Pointer to UDG Charset
	MEM0	EQU 5C92h ; Temporary memory buffer used by ROM chars
#line 5 "/zxbasic/src/arch/zx48k/library-asm/bright.asm"
BRIGHT:
		ld hl, ATTR_P
	    PROC
	    LOCAL IS_TR
	    LOCAL IS_ZERO
__SET_BRIGHT:
		; Another entry. This will set the bright flag at location pointer by DE
		cp 8
		jr z, IS_TR
		; # Convert to 0/1
		or a
		jr z, IS_ZERO
		ld a, 0x40
IS_ZERO:
		ld b, a	; Saves the color
		ld a, (hl)
		and 0BFh ; Clears previous value
		or b
		ld (hl), a
		inc hl
		res 6, (hl)  ;Reset bit 6 to disable transparency
		ret
IS_TR:  ; transparent
		inc hl ; Points DE to MASK_T or MASK_P
	    set 6, (hl)  ;Set bit 6 to enable transparency
		ret
	; Sets the BRIGHT flag passed in A register in the ATTR_T variable
BRIGHT_TMP:
		ld hl, ATTR_T
		jr __SET_BRIGHT
	    ENDP
#line 34 "attr_in_subs.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/cls.asm"
	; JUMPS directly to spectrum CLS
	; This routine does not clear lower screen
	;CLS	EQU	0DAFh
	; Our faster implementation
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
	; Printing positioning library.
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
#line 9 "/zxbasic/src/arch/zx48k/library-asm/cls.asm"
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
#line 35 "attr_in_subs.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
#line 4 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
COPY_ATTR:
		; Just copies current permanent attribs into temporal attribs
		; and sets print mode
		PROC
		LOCAL INVERSE1
		LOCAL __REFRESH_TMP
	INVERSE1 EQU 02Fh
		ld hl, (ATTR_P)
		ld (ATTR_T), hl
		ld hl, FLAGS2
		call __REFRESH_TMP
		ld hl, P_FLAG
		call __REFRESH_TMP
__SET_ATTR_MODE:		; Another entry to set print modes. A contains (P_FLAG)
#line 63 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
		ret
#line 65 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
__REFRESH_TMP:
		ld a, (hl)
		and 10101010b
		ld c, a
		rra
		or c
		ld (hl), a
		ret
		ENDP
#line 36 "attr_in_subs.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/ink.asm"
	; Sets ink color in ATTR_P permanently
; Parameter: Paper color in A register
INK:
		PROC
		LOCAL __SET_INK
		LOCAL __SET_INK2
		ld de, ATTR_P
__SET_INK:
		cp 8
		jr nz, __SET_INK2
		inc de ; Points DE to MASK_T or MASK_P
		ld a, (de)
		or 7 ; Set bits 0,1,2 to enable transparency
		ld (de), a
		ret
__SET_INK2:
		; Another entry. This will set the ink color at location pointer by DE
		and 7	; # Gets color mod 8
		ld b, a	; Saves the color
		ld a, (de)
		and 0F8h ; Clears previous value
		or b
		ld (de), a
		inc de ; Points DE to MASK_T or MASK_P
		ld a, (de)
		and 0F8h ; Reset bits 0,1,2 sign to disable transparency
		ld (de), a ; Store new attr
		ret
	; Sets the INK color passed in A register in the ATTR_T variable
INK_TMP:
		ld de, ATTR_T
		jp __SET_INK
		ENDP
#line 37 "attr_in_subs.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/paper.asm"
	; Sets paper color in ATTR_P permanently
; Parameter: Paper color in A register
PAPER:
		PROC
		LOCAL __SET_PAPER
		LOCAL __SET_PAPER2
		ld de, ATTR_P
__SET_PAPER:
		cp 8
		jr nz, __SET_PAPER2
		inc de
		ld a, (de)
		or 038h
		ld (de), a
		ret
		; Another entry. This will set the paper color at location pointer by DE
__SET_PAPER2:
		and 7	; # Remove
		rlca
		rlca
		rlca		; a *= 8
		ld b, a	; Saves the color
		ld a, (de)
		and 0C7h ; Clears previous value
		or b
		ld (de), a
		inc de ; Points to MASK_T or MASK_P accordingly
		ld a, (de)
		and 0C7h  ; Resets bits 3,4,5
		ld (de), a
		ret
	; Sets the PAPER color passed in A register in the ATTR_T variable
PAPER_TMP:
		ld de, ATTR_T
		jp __SET_PAPER
		ENDP
#line 38 "attr_in_subs.bas"
	END
