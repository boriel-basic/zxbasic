; Sets bright flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

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
