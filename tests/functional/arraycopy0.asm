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
_a:
	DEFB 00
_grid:
	DEFW __LABEL0
_grid.__DATA__.__PTR__:
	DEFW _grid.__DATA__
_grid.__DATA__:
	DEFB 00h
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
__LABEL0:
	DEFW 0000h
	DEFB 01h
_gridcopy:
	DEFW __LABEL1
_gridcopy.__DATA__.__PTR__:
	DEFW _gridcopy.__DATA__
_gridcopy.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
__LABEL1:
	DEFW 0000h
	DEFB 01h
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, 5
	ld b, h
	ld c, l
	ld hl, _grid.__DATA__
	ld de, _gridcopy.__DATA__
	ldir
	ld a, (_grid.__DATA__ + 0)
	ld (_a), a
	ld hl, 5
	ld b, h
	ld c, l
	ld hl, _grid.__DATA__
	ld de, _gridcopy.__DATA__
	ldir
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
	END
