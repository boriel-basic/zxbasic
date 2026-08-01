	org $0000
	jp $0100
	org $0008
	di
	halt
	org $0010
	di
	halt
	org $0018
	di
	halt
	org $0020
	di
	halt
	org $0028
	jp .core.FP_CALC_ENTRY
	org $0030
	di
	halt
	org $0038
	push af
.core.__RST38_WAIT:
	in   a, ($AF)
	and  $7E
	jr   z, .core.__RST38_WAIT
	pop  af
	ret
	org $0066
	retn
	org 256
.core.__START_PROGRAM:
	ld   b, 9
	ld   a, 1
	ld   c, 0xe7
	out  (c), a
	ld   b, 10
	ld   a, 2
	ld   c, 0xe7
	out  (c), a
	ld   b, 11
	ld   a, 3
	ld   c, 0xe7
	out  (c), a
	ld   b, 12
	ld   a, 4
	ld   c, 0xe7
	out  (c), a
	ld   b, 13
	ld   a, 5
	ld   c, 0xe7
	out  (c), a
	ld   b, 15
	ld   a, 7
	ld   c, 0xe7
	out  (c), a
	ld   sp, 0x7fff
	jp   .core.__MAIN_PROGRAM__
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
	halt
	;; --- end of user code ---
	END
