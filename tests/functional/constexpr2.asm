	xor a
	ld (__LABEL__label1 + 1), a
	xor a
	ld (2 + __LABEL__label1), a
	ld hl, __LABEL__label2 + __LABEL__label1 * 3
	ld (2 + __LABEL__label2 * 5 - __LABEL__label1), hl
	ld hl, (__LABEL__label2 + __LABEL__label1 * 3 & 0xFFFFFFFF) & 0xFFFF
	ld de, (__LABEL__label2 + __LABEL__label1 * 3 & 0xFFFFFFFF) >> 16
	ld (2 + __LABEL__label2 * 5 - __LABEL__label1), hl
	ld (2 + __LABEL__label2 * 5 - __LABEL__label1 + 2), de
	ld hl, (__LABEL__label2 + __LABEL__label1 * 3 & 0xFFFFFFFF) & 0xFFFF
	ld de, (__LABEL__label2 + __LABEL__label1 * 3 & 0xFFFFFFFF) >> 16
	ld (4), hl
	ld (4 + 2), de
	ld hl, (__LABEL__label1 + __LABEL__label2 & 0xFFFFFFFF) & 0xFFFF
	ld de, (__LABEL__label1 + __LABEL__label2 & 0xFFFFFFFF) >> 16
	ld (_a), hl
	ld (_a + 2), de
_a:
    DW 0
__LABEL__label1:
__LABEL__label2:

