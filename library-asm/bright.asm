; Sets bright flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

BRIGHT:
	ld de, ATTR_P

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
	ld a, (de)
	and 0BFh ; Clears previous value
	or b
	ld (de), a
	ret

IS_TR:  ; transparent
	inc de ; Points DE to MASK_T or MASK_P
	ld a, (de)
	or 0x40; Set bit 6 to enable transparency
	ld (de), a
	ret


; Sets the BRIGHT flag passed in A register in the ATTR_T variable
BRIGHT_TMP:
	ld de, ATTR_T
	jr __SET_BRIGHT
    ENDP
