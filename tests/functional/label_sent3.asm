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
__LABEL__0:
__LABEL__10:
	ld a, 1
	call BORDER
	ld a, 1
	call PAPER
	call COPY_ATTR
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
#line 1 "border.asm"

	; __FASTCALL__ Routine to change de border
	; Parameter (color) specified in A register

	BORDER EQU 229Bh

	; Nothing to do! (Directly from the ZX Spectrum ROM)

#line 25 "label_sent3.bas"
#line 1 "copy_attr.asm"

#line 4 "/src/zxb/trunk/library-asm/copy_attr.asm"

#line 1 "const.asm"

	; Global constants

	P_FLAG	EQU 23697
	FLAGS2	EQU 23681
	ATTR_P	EQU 23693	; permanet ATTRIBUTES
	ATTR_T	EQU 23695	; temporary ATTRIBUTES
	CHARS	EQU 23606 ; Pointer to ROM/RAM Charset
	UDG	EQU 23675 ; Pointer to UDG Charset
	MEM0	EQU 5C92h ; Temporary memory buffer used by ROM chars

#line 6 "copy_attr.asm"

COPY_ATTR:
		; Just copies current permanent attribs to temporal attribs
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

#line 63 "/src/zxb/trunk/library-asm/copy_attr.asm"
		ret
#line 65 "/src/zxb/trunk/library-asm/copy_attr.asm"

__REFRESH_TMP:
		ld a, (hl)
		and 10101010b
		ld c, a
		rra
		or c
		ld (hl), a
		ret

		ENDP

#line 26 "label_sent3.bas"
#line 1 "paper.asm"

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

#line 27 "label_sent3.bas"

ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
