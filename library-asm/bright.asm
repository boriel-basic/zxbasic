; Sets bright flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

BRIGHT:
	ld de, ATTR_P

__SET_BRIGHT:
	; Another entry. This will set the bright flag at location pointer by DE
	and 1	; # Convert to 0/1

	rrca
	rrca
	ld b, a	; Saves the color
	ld a, (de)
	and 0BFh ; Clears previous value
	or b
	ld (de), a
	ret


; Sets the BRIGHT flag passed in A register in the ATTR_T variable
BRIGHT_TMP:
	ld de, ATTR_T
	jr __SET_BRIGHT

