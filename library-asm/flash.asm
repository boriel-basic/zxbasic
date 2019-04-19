; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

FLASH:
	ld de, ATTR_P

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
	ld a, (de)
	and 07Fh ; Clears previous value
	or b
	ld (de), a
	ret

IS_TR:  ; transparent
	inc de ; Points DE to MASK_T or MASK_P
	ld a, (de)
	or 0x80; Set bit 7 to enable transparency
	ld (de), a
	ret

; Sets the FLASH flag passed in A register in the ATTR_T variable
FLASH_TMP:
	ld de, ATTR_T
	jr __SET_FLASH
    ENDP

