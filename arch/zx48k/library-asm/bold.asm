; Sets BOLD flag in P_FLAG permanently
; Parameter: BOLD flag in bit 0 of A register
#include once <copy_attr.asm>

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

