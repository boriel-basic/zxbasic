; Sets OVER flag in P_FLAG permanently
; Parameter: OVER flag in bit 0 of A register
#include once <copy_attr.asm>
#include once <const.asm>

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

