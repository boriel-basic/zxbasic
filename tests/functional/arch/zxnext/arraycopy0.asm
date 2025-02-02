	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
	DEFB 00
_grid:
	DEFW .LABEL.__LABEL0
_grid.__DATA__.__PTR__:
	DEFW _grid.__DATA__
	DEFW 0
	DEFW 0
_grid.__DATA__:
	DEFB 00h
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 01h
_gridcopy:
	DEFW .LABEL.__LABEL1
_gridcopy.__DATA__.__PTR__:
	DEFW _gridcopy.__DATA__
	DEFW 0
	DEFW 0
_gridcopy.__DATA__:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
.LABEL.__LABEL1:
	DEFW 0000h
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
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
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
	;; --- end of user code ---
	END
