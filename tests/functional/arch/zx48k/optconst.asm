	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_a:
	DEFB 00, 00, 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	xor a
	ld ((.LABEL._label1) + (1)), a
	xor a
	ld ((2) + (.LABEL._label1)), a
	ld hl, (.LABEL._label2) + ((.LABEL._label1) * (3))
	ld (((2) + ((.LABEL._label2) * (5))) - (.LABEL._label1)), hl
	ld hl, (((.LABEL._label2) + ((.LABEL._label1) * (3))) & 0xFFFFFFFF) & 0xFFFF
	ld de, (((.LABEL._label2) + ((.LABEL._label1) * (3))) & 0xFFFFFFFF) >> 16
	ld (((2) + ((.LABEL._label2) * (5))) - (.LABEL._label1)), hl
	ld (((2) + ((.LABEL._label2) * (5))) - (.LABEL._label1) + 2), de
	ld hl, (((.LABEL._label2) + ((.LABEL._label1) * (3))) & 0xFFFFFFFF) & 0xFFFF
	ld de, (((.LABEL._label2) + ((.LABEL._label1) * (3))) & 0xFFFFFFFF) >> 16
	ld (4), hl
	ld (4 + 2), de
	ld hl, (((.LABEL._label1) + (.LABEL._label2)) & 0xFFFFFFFF) & 0xFFFF
	ld de, (((.LABEL._label1) + (.LABEL._label2)) & 0xFFFFFFFF) >> 16
	ld (_a), hl
	ld (_a + 2), de
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	ld hl, (_a)
	ld de, (_a + 2)
	ld a, l
	ld (0), a
.LABEL._label1:
.LABEL._label2:
	ld hl, 0
	ld b, h
	ld c, l
	jp .core.__END_PROGRAM
	;; --- end of user code ---
	END
