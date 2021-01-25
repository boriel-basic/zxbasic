	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
_MultiKeys:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+5)
_MultiKeys__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_mainRoom:
	xor a
	push af
	call _MultiKeys
	or a
	jp z, __LABEL1
	ld a, 1
	ld (0), a
__LABEL1:
	ld a, 1
	push af
	call _MultiKeys
	or a
	jp z, __LABEL3
	xor a
	ld (1), a
__LABEL3:
	ld a, 2
	push af
	call _MultiKeys
	or a
	jp z, _mainRoom__leave
	xor a
	ld (2), a
_mainRoom__leave:
	ret
	;; --- end of user code ---
	END
