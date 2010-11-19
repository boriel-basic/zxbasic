; Sets ITALIC flag in P_FLAG permanently
; Parameter: ITALIC flag in bit 0 of A register
#include once <copy_attr.asm>

ITALIC:
	PROC

	and 1
    rrca
    rrca
    rrca
	ld hl, FLAGS2
	res 5, (HL)
	or (hl)
	ld (hl), a
	ret

; Sets ITALIC flag in P_FLAG temporarily
ITALIC_TMP:
	and 1
	rrca
	rrca
	rrca
	rrca
	ld hl, FLAGS2
	res 4, (hl)
	or (hl)
	ld (hl), a
	ret

	ENDP

