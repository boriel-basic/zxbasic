; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register

#include once <const.asm>

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

