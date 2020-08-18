; Sets INVERSE flag in P_FLAG permanently
; Parameter: INVERSE flag in bit 0 of A register

#include once <copy_attr.asm>

INVERSE:
	PROC

	and 1	; # Convert to 0/1
	add a, a; # Shift left 3 bits for permanent
	add a, a
	add a, a
	ld hl, P_FLAG
	res 3, (hl)
	or (hl)
	ld (hl), a
	ret

; Sets INVERSE flag in P_FLAG temporarily
INVERSE_TMP:
	and 1
	add a, a
	add a, a; # Shift left 2 bits for temporary
	ld hl, P_FLAG
	res 2, (hl)
	or (hl)
	ld (hl), a
	jp __SET_ATTR_MODE

	ENDP

