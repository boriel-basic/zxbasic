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
	xor a
	call INK
	call COPY_ATTR
	ld a, 7
	call PAPER
	call COPY_ATTR
	ld a, 1
	call FLASH
	call COPY_ATTR
	ld a, 1
	call OVER
	call COPY_ATTR
	ld a, 1
	call BOLD
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
#line 1 "bold.asm"

	; Sets BOLD flag in P_FLAG permanently
; Parameter: BOLD flag in bit 0 of A register
#line 1 "copy_attr.asm"

#line 4 "/zxbasic/library-asm/copy_attr.asm"

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

#line 63 "/zxbasic/library-asm/copy_attr.asm"
		ret
#line 65 "/zxbasic/library-asm/copy_attr.asm"

__REFRESH_TMP:
		ld a, (hl)
		and 10101010b
		ld c, a
		rra
		or c
		ld (hl), a
		ret

		ENDP

#line 4 "bold.asm"

BOLD:
		PROC

		and 1
		rlca
	    rlca
	    rlca
		ld hl, FLAGS2
		res 3, (HL)
		or (hl)
		ld (hl), a
		ret

	; Sets BOLD flag in P_FLAG temporarily
BOLD_TMP:
		and 1
		rlca
		rlca
		ld hl, FLAGS2
		res 2, (hl)
		or (hl)
		ld (hl), a
		ret

		ENDP

#line 33 "attr.bas"

#line 1 "flash.asm"

	; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register



FLASH:
		ld hl, ATTR_P

	    PROC
	    LOCAL IS_TR
	    LOCAL IS_ZERO

__SET_FLASH:
		; Another entry. This will set the flash flag at location pointer by DE
		cp 8
		jr z, IS_TR

		; # Convert to 0/1
		or a
		jr z, IS_ZERO
		ld a, 0x80

IS_ZERO:
		ld b, a	; Saves the color
		ld a, (hl)
		and 07Fh ; Clears previous value
		or b
		ld (hl), a
		inc hl
		res 7, (hl)  ;Reset bit 7 to disable transparency
		ret

IS_TR:  ; transparent
		inc hl ; Points DE to MASK_T or MASK_P
		set 7, (hl)  ;Set bit 7 to enable transparency
		ret

	; Sets the FLASH flag passed in A register in the ATTR_T variable
FLASH_TMP:
		ld hl, ATTR_T
		jr __SET_FLASH
	    ENDP

#line 35 "attr.bas"
#line 1 "ink.asm"

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

#line 36 "attr.bas"
#line 1 "over.asm"

	; Sets OVER flag in P_FLAG permanently
; Parameter: OVER flag in bit 0 of A register



OVER:
		PROC

		ld c, a ; saves it for later
		and 2
		ld hl, FLAGS2
		res 1, (HL)
		or (hl)
		ld (hl), a

		ld a, c	; Recovers previous value
		and 1	; # Convert to 0/1
		add a, a; # Shift left 1 bit for permanent

		ld hl, P_FLAG
		res 1, (hl)
		or (hl)
		ld (hl), a
		ret

	; Sets OVER flag in P_FLAG temporarily
OVER_TMP:
		ld c, a ; saves it for later
		and 2	; gets bit 1; clears carry
		rra
		ld hl, FLAGS2
		res 0, (hl)
		or (hl)
		ld (hl), a

		ld a, c	; Recovers previous value
		and 1
		ld hl, P_FLAG
		res 0, (hl)
	    or (hl)
		ld (hl), a
		jp __SET_ATTR_MODE

		ENDP

#line 37 "attr.bas"
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

#line 38 "attr.bas"

ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
