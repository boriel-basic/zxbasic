; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

FLASH:
	ld de, ATTR_P
__SET_FLASH:
	; Another entry. This will set the flash flag at location pointer by DE
	and 1	; # Convert to 0/1

	rrca
	ld b, a	; Saves the color
	ld a, (de)
	and 07Fh ; Clears previous value
	or b
	ld (de), a
	ret


; Sets the FLASH flag passed in A register in the ATTR_T variable
FLASH_TMP:
	ld de, ATTR_T
	jr __SET_FLASH

