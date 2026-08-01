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
	call .core.SD81_INIT_SYSVARS
	call .core.__MEM_INIT
	call .core.__PRINT_INIT
	jp   .core.__MAIN_PROGRAM__
.core.ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
.core.ZXBASIC_HEAP_SIZE EQU 16127
	; Defines HEAP ADDRESS
.core.ZXBASIC_MEM_HEAP EQU 33024
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	halt
_mid:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld l, (ix+8)
	ld h, (ix+9)
	ex de, hl
	pop hl
	add hl, de
	dec hl
	push hl
	xor a
	call .core.__STRSLICE
_mid__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_left:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld hl, 0
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	dec hl
	push hl
	xor a
	call .core.__STRSLICE
_left__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_right:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__STRLEN
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	push hl
	ld hl, 65534
	push hl
	xor a
	call .core.__STRSLICE
_right__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_strpos2:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -10
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 9
	ld d, h
	ld e, l
	inc de
	ldir
	ld h, (ix+5)
	ld l, (ix+4)
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	call .core.__STRLEN
	ld (ix-2), l
	ld (ix-1), h
	ld h, (ix+7)
	ld l, (ix+6)
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	call .core.__STRLEN
	ld (ix-4), l
	ld (ix-3), h
	ld l, (ix-4)
	ld h, (ix-3)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	pop de
	or a
	sbc hl, de
	jp nc, .LABEL.__LABEL1
	ld hl, 65535
	jp _strpos2__leave
.LABEL.__LABEL1:
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-4)
	ld h, (ix-3)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	ld (ix-6), l
	ld (ix-5), h
	ld l, (ix-4)
	ld h, (ix-3)
	dec hl
	ld (ix-8), l
	ld (ix-7), h
	ld (ix-10), 0
	ld (ix-9), 0
	jp .LABEL.__LABEL2
.LABEL.__LABEL5:
	ld h, (ix+7)
	ld l, (ix+6)
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	push hl
	ld h, (ix+5)
	ld l, (ix+4)
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	push hl
	ld l, (ix-10)
	ld h, (ix-9)
	push hl
	ld l, (ix-10)
	ld h, (ix-9)
	push hl
	ld l, (ix-8)
	ld h, (ix-7)
	ex de, hl
	pop hl
	add hl, de
	push hl
	xor a
	call .core.__STRSLICE
	ex de, hl
	pop hl
	ld a, 2
	call .core.__STREQ
	or a
	jp z, .LABEL.__LABEL8
	ld l, (ix-10)
	ld h, (ix-9)
	jp _strpos2__leave
.LABEL.__LABEL8:
.LABEL.__LABEL6:
	ld l, (ix-10)
	ld h, (ix-9)
	inc hl
	ld (ix-10), l
	ld (ix-9), h
.LABEL.__LABEL2:
	ld l, (ix-10)
	ld h, (ix-9)
	push hl
	ld l, (ix-6)
	ld h, (ix-5)
	pop de
	or a
	sbc hl, de
	jp nc, .LABEL.__LABEL5
.LABEL.__LABEL4:
	ld hl, 65535
_strpos2__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_strpos:
	push ix
	ld ix, 0
	add ix, sp
	push ix
	pop hl
	ld de, 6
	add hl, de
	push hl
	push ix
	pop hl
	ld de, 4
	add hl, de
	push hl
	call _strpos2
_strpos__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_inStr:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push ix
	pop hl
	ld de, 6
	add hl, de
	push hl
	push ix
	pop hl
	ld de, 4
	add hl, de
	push hl
	call _strpos2
	ld (ix-2), l
	ld (ix-1), h
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 65535
	pop hl
	or a
	sbc hl, de
	ld a, h
	or l
	sub 1
	sbc a, a
	inc a
_inStr__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_ucase2:
#line 125 "/zxbasic/src/lib/arch/zx48k/stdlib/string.bas"
		PROC
		LOCAL __LOOP
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		ld a, h
		or l
		ret z
		ld c, (hl)
		inc hl
		ld b, (hl)
__LOOP:
		inc hl
		ld a, b
		or c
		ret z
		ld a, (hl)
		dec bc
		cp 'a'
		jp c, __LOOP
		cp 123
		jp nc, __LOOP
		res 5,(hl)
		jp __LOOP
		ENDP
#line 166 "/zxbasic/src/lib/arch/zx48k/stdlib/string.bas"
_ucase2__leave:
	ret
_ucase:
	push ix
	ld ix, 0
	add ix, sp
	push ix
	pop hl
	ld de, 4
	add hl, de
	ld a, 1
	call _ucase2
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__LOADSTR
_ucase__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_lcase2:
#line 186 "/zxbasic/src/lib/arch/zx48k/stdlib/string.bas"
		PROC
		LOCAL __LOOP
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		ld a, h
		or l
		ret z
		ld c, (hl)
		inc hl
		ld b, (hl)
__LOOP:
		inc hl
		ld a, b
		or c
		ret z
		ld a, (hl)
		dec bc
		cp 'A'
		jp c, __LOOP
		cp 91
		jp nc, __LOOP
		set 5,(hl)
		jp __LOOP
		ENDP
#line 227 "/zxbasic/src/lib/arch/zx48k/stdlib/string.bas"
_lcase2__leave:
	ret
_lcase:
	push ix
	ld ix, 0
	add ix, sp
	push ix
	pop hl
	ld de, 4
	add hl, de
	ld a, 1
	call _lcase2
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__LOADSTR
_lcase__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_ltrim:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -8
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 7
	ld d, h
	ld e, l
	inc de
	ldir
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__STRLEN
	ld (ix-8), l
	ld (ix-7), h
	ld l, (ix-8)
	ld h, (ix-7)
	ld a, h
	or l
	jp nz, .LABEL.__LABEL10
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__LOADSTR
	jp _ltrim__leave
.LABEL.__LABEL10:
	ld l, (ix-8)
	ld h, (ix-7)
	dec hl
	ld (ix-4), l
	ld (ix-3), h
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__STRLEN
	ld (ix-6), l
	ld (ix-5), h
.LABEL.__LABEL11:
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-6)
	ld h, (ix-5)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	sbc a, a
	push af
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-4)
	ld h, (ix-3)
	ex de, hl
	pop hl
	add hl, de
	push hl
	xor a
	call .core.__STRSLICE
	ex de, hl
	pop hl
	ld a, 2
	call .core.__STREQ
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL33
	ld a, h
.LABEL.__LABEL33:
	or a
	jp z, .LABEL.__LABEL12
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-8)
	ld h, (ix-7)
	ex de, hl
	pop hl
	add hl, de
	ld (ix-2), l
	ld (ix-1), h
	jp .LABEL.__LABEL11
.LABEL.__LABEL12:
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld hl, 65534
	push hl
	xor a
	call .core.__STRSLICE
_ltrim__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_rtrim:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -8
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 7
	ld d, h
	ld e, l
	inc de
	ldir
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__STRLEN
	ld (ix-8), l
	ld (ix-7), h
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__STRLEN
	ld (ix-6), l
	ld (ix-5), h
	ld l, (ix-8)
	ld h, (ix-7)
	ld a, h
	or l
	sub 1
	sbc a, a
	push af
	ld l, (ix-6)
	ld h, (ix-5)
	push hl
	ld l, (ix-8)
	ld h, (ix-7)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	sbc a, a
	pop de
	or d
	jp z, .LABEL.__LABEL14
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__LOADSTR
	jp _rtrim__leave
.LABEL.__LABEL14:
	ld l, (ix-8)
	ld h, (ix-7)
	dec hl
	ld (ix-4), l
	ld (ix-3), h
	ld l, (ix-6)
	ld h, (ix-5)
	dec hl
	ld (ix-2), l
	ld (ix-1), h
.LABEL.__LABEL15:
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-4)
	ld h, (ix-3)
	pop de
	call .core.__LEI16
	push af
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-4)
	ld h, (ix-3)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	xor a
	call .core.__STRSLICE
	ex de, hl
	pop hl
	ld a, 2
	call .core.__STREQ
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL34
	ld a, h
.LABEL.__LABEL34:
	or a
	jp z, .LABEL.__LABEL16
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix-8)
	ld h, (ix-7)
	ex de, hl
	pop hl
	or a
	sbc hl, de
	ld (ix-2), l
	ld (ix-1), h
	jp .LABEL.__LABEL15
.LABEL.__LABEL16:
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 0
	pop hl
	call .core.__LTI16
	or a
	jp z, .LABEL.__LABEL18
	ld hl, .LABEL.__LABEL19
	call .core.__LOADSTR
	jp _rtrim__leave
.LABEL.__LABEL18:
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld hl, 0
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	xor a
	call .core.__STRSLICE
_rtrim__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_trim:
	push ix
	ld ix, 0
	add ix, sp
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__LOADSTR
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__LOADSTR
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__LOADSTR
	push hl
	call _rtrim
	push hl
	call _ltrim
_trim__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
_isdigit:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld hl, 0
	push hl
	ld hl, 0
	push hl
	xor a
	call .core.__STRSLICE
	ld a, 1
	call .core.__ASC
	ld (ix-1), a
	sub 48
	ccf
	sbc a, a
	push af
	ld a, (ix-1)
	push af
	ld a, 57
	pop hl
	sub h
	ccf
	sbc a, a
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL35
	ld a, h
.LABEL.__LABEL35:
	sub 1
	sbc a, a
	inc a
_isdigit__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_isletter:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	inc sp
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld hl, 0
	push hl
	ld hl, 0
	push hl
	xor a
	call .core.__STRSLICE
	ld a, 1
	call .core.__ASC
	ld (ix-1), a
	sub 97
	ccf
	sbc a, a
	push af
	ld a, (ix-1)
	push af
	ld a, 122
	pop hl
	sub h
	ccf
	sbc a, a
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL36
	ld a, h
.LABEL.__LABEL36:
	push af
	ld a, (ix-1)
	sub 65
	ccf
	sbc a, a
	push af
	ld a, (ix-1)
	push af
	ld a, 90
	pop hl
	sub h
	ccf
	sbc a, a
	ld h, a
	pop af
	or a
	jr z, .LABEL.__LABEL37
	ld a, h
.LABEL.__LABEL37:
	pop de
	or d
	sub 1
	sbc a, a
	inc a
_isletter__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_SNETsocket:
#line 59 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld c, a
		ld hl, Spectranet.SOCKET
		call Spectranet.HLCALL
#line 64 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETsocket__leave:
	ret
_SNETbind:
#line 68 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		ex (sp), hl
		ex de, hl
		ld hl, Spectranet.BIND
		call Spectranet.HLCALL
#line 75 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETbind__leave:
	ret
_SNETlisten:
#line 79 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.LISTEN
		call Spectranet.HLCALL
#line 83 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETlisten__leave:
	ret
_SNETaccept:
#line 87 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.ACCEPT
		call Spectranet.HLCALL
#line 91 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETaccept__leave:
	ret
_SNETconnect:
#line 95 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop de
		pop bc
		push hl
		ld hl, Spectranet.CONNECT
		push de
		inc de
		inc de
		call Spectranet.HLCALL
		pop hl
		ex af, af'
		call __MEM_FREE
		ex af, af'
#line 110 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETconnect__leave:
	ret
_SNETclose:
#line 114 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.CLOSE
		call Spectranet.HLCALL
#line 118 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETclose__leave:
	ret
_SNETrecv:
#line 122 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop de
		pop bc
		push hl
		ld hl, Spectranet.RECV
		call Spectranet.HLCALL
#line 130 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETrecv__leave:
	ret
_SNETsend:
#line 134 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop de
		pop bc
		push hl
		ld hl, Spectranet.SEND
		call Spectranet.HLCALL
#line 142 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETsend__leave:
	ret
_SNETpollfd:
#line 146 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.POLLFD
		call Spectranet.HLCALL
		ld a, 0
		ret z
		ld c, a
#line 153 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETpollfd__leave:
	ret
_SNETpeekUinteger:
#line 160 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ex de, hl
		ld hl, Spectranet.PAGEIN
		call Spectranet.HLCALL
		ex de, hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		ld hl, Spectranet.PAGEOUT
		call Spectranet.HLCALL
		ex de, hl
#line 172 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETpeekUinteger__leave:
	ret
_SNETmount:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -8
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 7
	ld d, h
	ld e, l
	inc de
	ldir
	ld hl, -8
	ld de, .LABEL.__LABEL38
	ld bc, 10
	call .core.__ALLOC_LOCAL_ARRAY
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 6
	call .core.__PSTORE_STR2
	ld l, (ix+8)
	ld h, (ix+9)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 8
	call .core.__PSTORE_STR2
	ld l, (ix+10)
	ld h, (ix+11)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 10
	call .core.__PSTORE_STR2
	ld l, (ix+12)
	ld h, (ix+13)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 12
	call .core.__PSTORE_STR2
	ld l, (ix+14)
	ld h, (ix+15)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 14
	call .core.__PSTORE_STR2
	ld l, (ix-6)
	ld h, (ix-5)
	push hl
	push ix
	pop hl
	ld de, 6
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld l, (ix-6)
	ld h, (ix-5)
	inc hl
	inc hl
	push hl
	push ix
	pop hl
	ld de, 8
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld l, (ix-6)
	ld h, (ix-5)
	ld de, 4
	add hl, de
	push hl
	push ix
	pop hl
	ld de, 10
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld l, (ix-6)
	ld h, (ix-5)
	ld de, 6
	add hl, de
	push hl
	push ix
	pop hl
	ld de, 12
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld l, (ix-6)
	ld h, (ix-5)
	ld de, 8
	add hl, de
	push hl
	push ix
	pop hl
	ld de, 14
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, 0
	push hl
	push ix
	pop hl
	ld de, -8
	add hl, de
	call .core.__ARRAY
	ld (ix-2), l
	ld (ix-1), h
#line 203 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld a, (ix + 5)
		push ix
		push hl
		pop ix
		ld hl, Spectranet.MOUNT
		call Spectranet.HLCALL
		pop ix
#line 212 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETmount__leave:
	ex af, af'
	exx
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__MEM_FREE
	ld l, (ix+10)
	ld h, (ix+11)
	call .core.__MEM_FREE
	ld l, (ix+12)
	ld h, (ix+13)
	call .core.__MEM_FREE
	ld l, (ix+14)
	ld h, (ix+15)
	call .core.__MEM_FREE
	ld l, (ix-6)
	ld h, (ix-5)
	call .core.__MEM_FREE
	ex af, af'
	ld hl, 12
__EXIT_FUNCTION:
	ld sp, ix
	pop ix
	pop de
	add hl, sp
	ld sp, hl
	push de
	exx
	ret
_SNETcurrMPoint:
	push ix
	ld ix, 0
	add ix, sp
	call .core.COPY_ATTR
	ld a, 7
	call .core.INK_TMP
	ld a, 2
	call .core.PAPER_TMP
	ld hl, 4097
	call _SNETpeekUinteger
	ld a, l
	call .core.__PRINTU8
	call .core.PRINT_EOL
	ld hl, 4097
	call _SNETpeekUinteger
	ld a, l
_SNETcurrMPoint__leave:
	ld sp, ix
	pop ix
	ret
_SNETsetmountpt:
#line 228 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.SETMOUNTPOINT
		call Spectranet.HLCALL
#line 232 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETsetmountpt__leave:
	ret
_SNETumount:
#line 242 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.UMOUNT
		call Spectranet.HLCALL
#line 246 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETumount__leave:
	ret
_SNETopen:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 6
	call .core.__PSTORE_STR2
	push ix
	pop hl
	ld de, 6
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ld (ix-2), l
	ld (ix-1), h
#line 268 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld a, (ix + 5)
		ld e, (ix + 8)
		ld d, (ix + 9)
		ld c, (ix + 10)
		ld b, (ix + 11)
		push ix
		ld ix, Spectranet.OPEN
		call Spectranet.IXCALL
		pop ix
#line 280 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETopen__leave:
	ex af, af'
	exx
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_SNETfread:
#line 292 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop de
		pop bc
		push hl
		ld hl, Spectranet.READ
		call Spectranet.HLCALL
		ld h, b
		ld c, l
		ret nc
		ld (23610), a
#line 304 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETfread__leave:
	ret
_SNETfwrite:
#line 316 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop de
		pop bc
		push hl
		ex de, hl
		push ix
		ld ix, Spectranet.WRITE
		call Spectranet.IXCALL
		pop ix
		ld h, b
		ld c, l
		ret nc
		ld (23610), a
#line 331 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETfwrite__leave:
	ret
_SNETfopen:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld hl, .LABEL.__LABEL21
	call .core.__LOADSTR
	push hl
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__LOADSTR
	push hl
	call _inStr
	or a
	jp z, .LABEL.__LABEL23
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 1
	pop hl
	call .core.__BOR16
	ld (ix-2), l
	ld (ix-1), h
.LABEL.__LABEL23:
	ld hl, .LABEL.__LABEL24
	call .core.__LOADSTR
	push hl
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__LOADSTR
	push hl
	call _inStr
	or a
	jp z, .LABEL.__LABEL26
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 256
	pop hl
	call .core.__BOR16
	push hl
	ld de, 512
	pop hl
	call .core.__BOR16
	push hl
	ld de, 2
	pop hl
	call .core.__BOR16
	ld (ix-2), l
	ld (ix-1), h
.LABEL.__LABEL26:
	ld hl, .LABEL.__LABEL27
	call .core.__LOADSTR
	push hl
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__LOADSTR
	push hl
	call _inStr
	or a
	jp z, .LABEL.__LABEL29
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 8
	pop hl
	call .core.__BOR16
	push hl
	ld de, 256
	pop hl
	call .core.__BOR16
	push hl
	ld de, 2
	pop hl
	call .core.__BOR16
	ld (ix-2), l
	ld (ix-1), h
.LABEL.__LABEL29:
	ld hl, .LABEL.__LABEL30
	call .core.__LOADSTR
	push hl
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__LOADSTR
	push hl
	call _inStr
	or a
	jp z, .LABEL.__LABEL32
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld de, 3
	pop hl
	call .core.__BOR16
	ld (ix-2), l
	ld (ix-1), h
.LABEL.__LABEL32:
	ld hl, 438
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__LOADSTR
	push hl
	ld a, (ix+5)
	push af
	call _SNETopen
_SNETfopen__leave:
	ex af, af'
	exx
	ld l, (ix+6)
	ld h, (ix+7)
	call .core.__MEM_FREE
	ld l, (ix+8)
	ld h, (ix+9)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_SNETfclose:
#line 366 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		ld hl, Spectranet.CLOSE
		call Spectranet.HLCALL
		ret c
		xor a
#line 372 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETfclose__leave:
	ret
_SNETfseek:
#line 383 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		pop hl
		pop bc
		ld c, b
		pop de
		ex (sp), hl
		ex de, hl
		push ix
		ld ix, Spectranet.LSEEK
		call Spectranet.IXCALL
		pop ix
		ret c
		xor a
#line 398 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETfseek__leave:
	ret
_SNETunlink:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	push hl
	ld de, .LABEL.__LABEL20
	pop hl
	call .core.__ADDSTR
	ld d, h
	ld e, l
	ld bc, 4
	call .core.__PSTORE_STR2
	push ix
	pop hl
	ld de, 4
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	inc hl
	inc hl
	ld (ix-2), l
	ld (ix-1), h
#line 411 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
		PROC
		LOCAL CONT
		push ix
		ld ix, Spectranet.UNLINK
		call Spectranet.IXCALL
		pop ix
		jr c, CONT
		xor a
CONT:
		ENDP
#line 423 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
_SNETunlink__leave:
	ex af, af'
	exx
	ld l, (ix+4)
	ld h, (ix+5)
	call .core.__MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
.LABEL.__LABEL19:
	DEFW 0000h
.LABEL.__LABEL20:
	DEFW 0001h
	DEFB 00h
.LABEL.__LABEL21:
	DEFW 0001h
	DEFB 72h
.LABEL.__LABEL24:
	DEFW 0001h
	DEFB 77h
.LABEL.__LABEL27:
	DEFW 0001h
	DEFB 61h
.LABEL.__LABEL30:
	DEFW 0001h
	DEFB 2Bh
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	; -------------------------------------------------------------------
	; Simple array Index routine
	; Number of total indexes dimensions - 1 at beginning of memory
	; HL = Start of array memory (First two bytes contains N-1 dimensions)
	; Dimension values on the stack, (top of the stack, highest dimension)
	; E.g. A(2, 4) -> PUSH <4>; PUSH <2>
	; For any array of N dimension A(aN-1, ..., a1, a0)
	; and dimensions D[bN-1, ..., b1, b0], the offset is calculated as
	; O = [a0 + b0 * (a1 + b1 * (a2 + ... bN-2(aN-1)))]
; What I will do here is to calculate the following sequence:
	; ((aN-1 * bN-2) + aN-2) * bN-3 + ...
	;
; zx81sd override: the only change from zx48k's version is
	; LBOUND_PTR's storage address. The original uses the Spectrum ROM's
	; MEMBOT system variable (23698, safe scratch RAM on real hardware) --
	; on zx81sd that address falls inside the program's own compiled code
	; (block 2, $4000-$5FFF) instead of a real sysvar, silently corrupting
	; it on every multi-dimensional array access. ARRAY_SCRATCH (sysvars.asm)
	; is a dedicated 8-byte scratch area in the zx81sd sysvar block instead.
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/fmul16.asm"
	;; Performs a faster multiply for little 16bit numbs
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/mul16.asm"
	    push namespace core
__MUL16:	; Mutiplies HL with the last value stored into de stack
	    ; Works for both signed and unsigned
	    PROC
	    LOCAL __MUL16LOOP
	    LOCAL __MUL16NOADD
	    ex de, hl
	    pop hl		; Return address
	    ex (sp), hl ; CALLEE caller convention
__MUL16_FAST:
	    ld b, 16
	    ld a, h
	    ld c, l
	    ld hl, 0
__MUL16LOOP:
	    add hl, hl  ; hl << 1
	    sla c
	    rla         ; a,c << 1
	    jp nc, __MUL16NOADD
	    add hl, de
__MUL16NOADD:
	    djnz __MUL16LOOP
	    ret	; Result in hl (16 lower bits)
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/arith/fmul16.asm"
	    push namespace core
__FMUL16:
	    xor a
	    or h
	    jp nz, __MUL16_FAST
	    or l
	    ret z
	    cp 33
	    jp nc, __MUL16_FAST
	    ld b, l
	    ld l, h  ; HL = 0
1:
	    add hl, de
	    djnz 1b
	    ret
	    pop namespace
#line 27 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/sysvars.asm"
	; -----------------------------------------------------------------------
	; ZX81 + SD81 Booster System Variables
	;
; SCREEN_ADDR / SCREEN_ATTR_ADDR: bloque 6 ($C000), pantalla Spectrum
	; emulada por la FPGA del SD81 Booster en modo Superfast HiRes Spectrum.
	;
	; Las variables dinámicas del runtime se sitúan en $8000+ (bloques 4-5),
	; fuera de la zona de código ejecutable ($0000-$7FFF), para no partir
	; el espacio de ejecución del usuario.
	; -----------------------------------------------------------------------
	; Estos ficheros se incluyen siempre a través de sysvars.asm (primer fichero
	; en incluirse en cualquier programa zx81sd) para que sus #init se registren
	; en la primera pasada del preprocesador, antes de que emit_prologue() genere
	; las llamadas CALL a las rutinas de inicialización.
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/bootstrap.asm"
	; BOOTSTRAP — Inicialización de las sysvars del runtime (stage 2, parte ASM)
	;
	; El hardware (paginación bloques 1-5, SP, DI) es inicializado directamente
	; por el prólogo del backend Python (emit_prologue), que emite esas
	; instrucciones como constantes de arquitectura conocidas en tiempo de
	; compilación.
	;
	; Esta rutina se ocupa de los valores por defecto de las sysvars en $8000+.
	; Se registra con #init para que el compilador inserte automáticamente
	; CALL SD81_INIT_SYSVARS en el prólogo, justo antes del salto al programa.
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/charset.asm"
	; CHARSET — Fuente de caracteres 8x8 compatible Spectrum
	;
	; 96 caracteres × 8 bytes, desde CHR$(32) hasta CHR$(127).
; Fichero externo: specfont.bin (debe estar en el mismo directorio).
	    push namespace core
__ZX81SD_CHARSET:
	    INCBIN "specfont.bin"
	; Area de UDGs (CHR$(144) a CHR$(164), 21 caracteres como en el Spectrum).
; La fuente solo cubre CHR$(32)-CHR$(127) (768 bytes): sin este bloque,
	; apuntar UDG a "font+896" caia 128 bytes MAS ALLA del final de la fuente,
	; sobre el codigo que tocara despues en el enlazado (los POKE USR CHR$
	; de un programa corrompian el runtime). SD81_INIT_SYSVARS la inicializa
	; con copias de las letras A-U, igual que la ROM del Spectrum.
__ZX81SD_UDG_AREA:
	    defs 21 * 8
	    pop namespace
#line 14 "/zxbasic/src/lib/arch/zx81sd/runtime/bootstrap.asm"
; fp_calc.asm se incluye siempre (no solo cuando el programa usa FLOAT):
	; el vector RST $28h (src/arch/zx81sd/backend/main.py, emit_prologue) salta
	; incondicionalmente a FP_CALC_ENTRY, así que esa etiqueta debe existir en
	; todo binario, aunque el programa concreto no acabe generando código que
	; la invoque.
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/fp_calc.asm"
	; ===========================================================================
	; fp_calc.asm — Calculador de coma flotante (RST $28h) para ZX81 + SD81 Booster
	;
	; Port del calculador de la ROM del ZX Spectrum 48K (CALCULATE, $335B, y las
	; rutinas de las que depende) a código propio en RAM, ya que en zx81sd no hay
	; ninguna ROM mapeada en tiempo de ejecucion (el bloque 0 lo ocupa entero
	; nuestro binario compilado).
	;
	; Gracias a este port, todo el runtime de coma flotante de zx48k (addf.asm,
	; subf.asm, mulf.asm, divf.asm, negf.asm, cmp/*.asm, bool/*.asm, math/*.asm,
	; str.asm, printf.asm, val.asm...) funciona TAL CUAL, sin modificar ni un
; solo fichero: todos ellos hacen "rst 28h" seguido de bytes de "literal" de
	; operacion calculadora, y ahora $0028 contiene codigo real (ver
	; src/arch/zx81sd/backend/main.py, emit_prologue) en vez de un DI/HALT.
	;
; FASE 1 (este fichero): motor CALCULATE + pila de numeros FP + aritmetica
	; (suma/resta/multiplicacion/division) + comparaciones numericas + booleanas
	; (AND/OR/NOT) + funciones unarias basicas (ABS/NEGATE/SGN/INT/truncate).
; Pendiente en fases posteriores: SIN/COS/TAN/ASN/ACS/ATN/LN/EXP/SQR (usan el
	; "series generator" ya portado aqui, mas la tabla de coeficientes de cada
	; funcion, que aun no esta), STR$ (conversion numero->texto) y VAL (parseo de
; texto->numero, con semantica simplificada: solo literales decimales, no
	; evaluacion de expresiones completas como hace la ROM real — ver conversacion
	; de diseño).
	;
; Formato de los numeros (5 bytes), identico al de la ROM Spectrum:
;   Entero pequeño:  byte1=$00, byte2=signo($00/$FF), byte3=lo, byte4=hi, byte5=$00
;   Coma flotante:   byte1=exponente sesgado(+$80), byte2..5=mantisa de 32 bits
	;                    con el bit 7 del byte2 usado como signo (bit de mantisa
	;                    implicito, siempre a 1 salvo cuando se usa para el signo)
	;
; Referencia: disassembly comentado de la ROM del ZX Spectrum 48K
; (C:\ClaudeCode\ZXBASIC-SD81\Spectrum48.asm), seccion "FLOATING-POINT
	; CALCULATOR". Las etiquetas Lxxxx conservan la direccion original de la ROM
; (solo como identificador legible, no como direccion real: aqui son
	; reubicables) para facilitar la referencia cruzada con el disassembly.
	; ===========================================================================
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/error.asm"
	; Simple error control routines — ZX81 + SD81 Booster
	; Sustituye RST 8 (error handler de la ROM Spectrum) por una parada
; limpia: guarda el código de error en ERR_NR y detiene la CPU.
	; Las interrupciones ya están desactivadas (DI desde el bootstrap).
	    push namespace core
	; Códigos de error (compatibles con el manual del ZX Spectrum)
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	; __ERROR — Detiene la ejecución con un código de error en A.
; Sustituye a: RST 8 (ROM Spectrum)
__ERROR:
	    ld (__ERROR_CODE), a
	    ld (ERR_NR), a          ; guardar en sysvar
	    di                      ; asegurar interrupciones desactivadas
	    halt                    ; detener CPU
__ERROR_CODE:
	    nop                     ; byte de código de error (para compatibilidad con llamadores)
	    ret                     ; no se alcanza, pero mantiene la estructura original
	; __STOP — Guarda el código de error y continúa (para END del programa).
__STOP:
	    ld (ERR_NR), a
	    ret
	    pop namespace
#line 41 "/zxbasic/src/lib/arch/zx81sd/runtime/fp_calc.asm"
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/stackf.asm"
	; stackf.asm (zx81sd) — Gestión de la pila del calculador FP
	;
	; Sustituye a zx48k/runtime/stackf.asm, que define __FPSTACK_PUSH/POP como
	; direcciones FIJAS de la ROM del Spectrum ($2AB6h STK-STORE, $2BF1h
	; STK-FETCH). En zx81sd esas direcciones son parte de nuestro propio
	; binario compilado (varían de un programa a otro), así que no se pueden
	; usar como constantes — hay que reimplementar ambas rutinas como código
	; reubicable normal, usando fp_calc.asm (mismo formato de pila y de número
	; de 5 bytes que el motor CALCULATE ya portado).
	    push namespace core
	; ---------------------------------------------------------------------------
	; __FPSTACK_PUSH — Apila los registros A,E,D,C,B (5 bytes) en la pila FP
	; Sustituye a STK-STORE ($2AB6h ROM Spectrum)
	; ---------------------------------------------------------------------------
__FPSTACK_PUSH:
	    push bc
	    push af
	    ld   bc, 5
	    call CALC_TEST_ROOM
	    pop  af
	    pop  bc
	    ld   hl, (FP_STKEND)
	    ld   (hl), a
	    inc  hl
	    ld   (hl), e
	    inc  hl
	    ld   (hl), d
	    inc  hl
	    ld   (hl), c
	    inc  hl
	    ld   (hl), b
	    inc  hl
	    ld   (FP_STKEND), hl
	    ret
__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	    ; Second argument to push into the stack calculator is popped out of the stack
	    ; Since the caller routine also receives the parameters into the top of the stack
	    ; four bytes must be removed from SP before pop them out
	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr
	    pop af
	    pop de
	    pop bc
	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx
	    jp __FPSTACK_PUSH
__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
	    ; This format is specified in the ZX 48K Manual
	    ; You can push a 16 bit signed integer as
	    ; 0 SS LL HH 0, being SS the sign and LL HH the low
	    ; and High byte respectively
	    ld a, h
	    rla			; sign to Carry
	    sbc	a, a	; 0 if positive, FF if negative
	    ld e, a
	    ld d, l
	    ld c, h
	    xor a
	    ld b, a
	    jp __FPSTACK_PUSH
	; ---------------------------------------------------------------------------
	; __FPSTACK_POP — Extrae los últimos 5 bytes de la pila FP a A,E,D,C,B
	; Sustituye a STK-FETCH ($2BF1h ROM Spectrum)
	; ---------------------------------------------------------------------------
__FPSTACK_POP:
	    ld   hl, (FP_STKEND)
	    dec  hl
	    ld   b, (hl)
	    dec  hl
	    ld   c, (hl)
	    dec  hl
	    ld   d, (hl)
	    dec  hl
	    ld   e, (hl)
	    dec  hl
	    ld   a, (hl)
	    ld   (FP_STKEND), hl
	    ret
	    pop namespace
#line 42 "/zxbasic/src/lib/arch/zx81sd/runtime/fp_calc.asm"
; fp_calc.asm se incluye siempre (no solo cuando el programa usa FLOAT):
	; ver src/arch/zx81sd/backend/main.py. Por eso debe bastarse a si mismo e
	; incluir aqui stackf.asm (de donde vienen __FPSTACK_PUSH/__FPSTACK_POP),
	; en vez de depender de que el fichero que lo incluya lo haga tambien.
	    push namespace core
	; ---------------------------------------------------------------------------
	; Punto de entrada — sustituye a RST $28h
	; ---------------------------------------------------------------------------
FP_CALC_ENTRY:
	    jp L335B
	; ---------------------------------------------------------------------------
	; TEST-ROOM propio — sustituye a TEST-ROOM ($1F05, que comprobaba espacio
	; libre contra el puntero de pila SP). Aqui la pila de numeros FP es un
	; buffer fijo (FP_CALC_STACK..FP_CALC_STACK_END en sysvars.asm), asi que
	; basta comprobar que FP_STKEND + BC no se sale del buffer.
; Entrada: BC = bytes requeridos. Sale con BC intacto si hay espacio.
	; ---------------------------------------------------------------------------
CALC_TEST_ROOM:
	    push hl
	    push de
	    ld   hl, (FP_STKEND)
	    add  hl, bc
	    ld   de, FP_CALC_STACK_END
	    or   a
	    sbc  hl, de
	    pop  de
	    pop  hl
	    jr   c, CALC_TEST_ROOM_OK
	    ld   a, ERROR_OutOfMemory
	    jp   __ERROR
CALC_TEST_ROOM_OK:
	    ret
	; ---------------------------------------------------------------------------
	; THE 'TEST FIVE SPACES' SUBROUTINE ($33A9 TEST-5-SP)
	; ---------------------------------------------------------------------------
L33A9:
	    push de
	    push hl
	    ld   bc, 5
	    call CALC_TEST_ROOM
	    pop  hl
	    pop  de
	    ret
	; ---------------------------------------------------------------------------
	; STACK-NUM ($33B4) — apila un numero de 5 bytes apuntado por HL
	; ---------------------------------------------------------------------------
L33B4:
	    ld   de, (FP_STKEND)
	    call L33C0
	    ld   (FP_STKEND), de
	    ret
	; ---------------------------------------------------------------------------
	; MOVE-FP / duplicate (literal $31, $33C0)
	; ---------------------------------------------------------------------------
L33C0:
	    call L33A9
	    ldir
	    ret
	; ---------------------------------------------------------------------------
	; stk-data (literal $34, $33C6) / STK-CONST ($33C8) / STK-ZEROS ($33F1)
	; ---------------------------------------------------------------------------
L33C6:
	    ld   h, d
	    ld   l, e
L33C8:
	    call L33A9
	    exx
	    push hl
	    exx
	    ex   (sp), hl
	    push bc
	    ld   a, (hl)
	    and  $C0
	    rlca
	    rlca
	    ld   c, a
	    inc  c
	    ld   a, (hl)
	    and  $3F
	    jr   nz, L33DE
	    inc  hl
	    ld   a, (hl)
L33DE:
	    add  a, $50
	    ld   (de), a
	    ld   a, 5
	    sub  c
	    inc  hl
	    inc  de
	    ld   b, 0
	    ldir
	    pop  bc
	    ex   (sp), hl
	    exx
	    pop  hl
	    exx
	    ld   b, a
	    xor  a
L33F1:
	    dec  b
	    ret  z
	    ld   (de), a
	    inc  de
	    jr   L33F1
	; ---------------------------------------------------------------------------
	; SKIP-CONS ($33F7 / $33F8)
	; ---------------------------------------------------------------------------
L33F7:
	    and  a
L33F8:
	    ret  z
	    push af
	    push de
	    ld   de, 0
	    call L33C8
	    pop  de
	    pop  af
	    dec  a
	    jr   L33F8
	; ---------------------------------------------------------------------------
	; LOC-MEM ($3406)
	; ---------------------------------------------------------------------------
L3406:
	    ld   c, a
	    rlca
	    rlca
	    add  a, c
	    ld   c, a
	    ld   b, 0
	    add  hl, bc
	    ret
	; ---------------------------------------------------------------------------
	; get-mem-xx (literales $E0-$FF, $340F)
	; ---------------------------------------------------------------------------
L340F:
	    push de
	    ld   hl, (FP_MEM)
	    call L3406
	    call L33C0
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; stk-const-xx (literales $A0-$BF, $341B) + tabla de constantes
	; ---------------------------------------------------------------------------
L341B:
	    ld   h, d
	    ld   l, e
	    exx
	    push hl
	    ld   hl, L32C5
	    exx
	    call L33F7
	    call L33C8
	    exx
	    pop  hl
	    exx
	    ret
	; ---------------------------------------------------------------------------
	; st-mem-xx (literales $C0-$DF, $342D)
	; ---------------------------------------------------------------------------
L342D:
	    push hl
	    ex   de, hl
	    ld   hl, (FP_MEM)
	    call L3406
	    ex   de, hl
	    call L33C0
	    ex   de, hl
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; exchange (literal $01, $343C)
	; ---------------------------------------------------------------------------
L343C:
	    ld   b, 5
L343E:
	    ld   a, (de)
	    ld   c, (hl)
	    ex   de, hl
	    ld   (de), a
	    ld   (hl), c
	    inc  hl
	    inc  de
	    djnz L343E
	    ex   de, hl
	    ret
	; ---------------------------------------------------------------------------
	; series generator (literales $80-$9F, $3449) — necesario para SIN/COS/EXP/LN
	; (aun sin las tablas de coeficientes; se añadirán en una fase posterior)
	; ---------------------------------------------------------------------------
L3449:
	    ld   b, a
	    call L335E
	    defb $31            ;;duplicate       x,x
	    defb $0F            ;;addition        x+x
	    defb $C0            ;;st-mem-0        x+x
	    defb $02            ;;delete          .
	    defb $A0            ;;stk-zero        0
	    defb $C2            ;;st-mem-2        0
L3453:
	    defb $31            ;;duplicate       v,v.
	    defb $E0            ;;get-mem-0       v,v,x+2
	    defb $04            ;;multiply        v,v*x+2
	    defb $E2            ;;get-mem-2       v,v*x+2,v
	    defb $C1            ;;st-mem-1
	    defb $03            ;;subtract
	    defb $38            ;;end-calc
	    call L33C6
	    call L3362
	    defb $0F            ;;addition
	    defb $01            ;;exchange
	    defb $C2            ;;st-mem-2
	    defb $02            ;;delete
	    defb $35            ;;dec-jr-nz
	    defb (L3453 - $) & 0FFh   ;;back to G-LOOP
	    defb $E1            ;;get-mem-1
	    defb $03            ;;subtract
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; abs (literal $2A, $346A) / negate (literal $1B, $346E) / sgn (literal $29,
	; $3492)
	; ---------------------------------------------------------------------------
L346A:
	    ld   b, $FF
	    jr   L3474
L346E:
	    call L34E9
	    ret  c
	    ld   b, 0
L3474:
	    ld   a, (hl)
	    and  a
	    jr   z, L3483
	    inc  hl
	    ld   a, b
	    and  $80
	    or   (hl)
	    rla
	    ccf
	    rra
	    ld   (hl), a
	    dec  hl
	    ret
L3483:
	    push de
	    push hl
	    call L2D7F
	    pop  hl
	    ld   a, b
	    or   c
	    cpl
	    ld   c, a
	    call L2D8E
	    pop  de
	    ret
L3492:
	    call L34E9
	    ret  c
	    push de
	    ld   de, 1
	    inc  hl
	    rl   (hl)
	    dec  hl
	    sbc  a, a
	    ld   c, a
	    call L2D8E
	    pop  de
	    ret
	; ---------------------------------------------------------------------------
	; INT-FETCH ($2D7F) / INT-STORE ($2D8E)
	; ---------------------------------------------------------------------------
L2D7F:
	    inc  hl
	    ld   c, (hl)
	    inc  hl
	    ld   a, (hl)
	    xor  c
	    sub  c
	    ld   e, a
	    inc  hl
	    ld   a, (hl)
	    adc  a, c
	    xor  c
	    ld   d, a
	    ret
L2D8E:
	    push hl
	    ld   (hl), 0
	    inc  hl
	    ld   (hl), c
	    inc  hl
	    ld   a, e
	    xor  c
	    sub  c
	    ld   (hl), a
	    inc  hl
	    ld   a, d
	    adc  a, c
	    xor  c
	    ld   (hl), a
	    inc  hl
	    ld   (hl), 0
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; PREP-ADD ($2F9B)
	; ---------------------------------------------------------------------------
L2F9B:
	    ld   a, (hl)
	    ld   (hl), 0
	    and  a
	    ret  z
	    inc  hl
	    bit  7, (hl)
	    set  7, (hl)
	    dec  hl
	    ret  z
	    push bc
	    ld   bc, 5
	    add  hl, bc
	    ld   b, c
	    ld   c, a
	    scf
L2FAF:
	    dec  hl
	    ld   a, (hl)
	    cpl
	    adc  a, 0
	    ld   (hl), a
	    djnz L2FAF
	    ld   a, c
	    pop  bc
	    ret
	; ---------------------------------------------------------------------------
	; FETCH-TWO ($2FBA)
	; ---------------------------------------------------------------------------
L2FBA:
	    push hl
	    push af
	    ld   c, (hl)
	    inc  hl
	    ld   b, (hl)
	    ld   (hl), a
	    inc  hl
	    ld   a, c
	    ld   c, (hl)
	    push bc
	    inc  hl
	    ld   c, (hl)
	    inc  hl
	    ld   b, (hl)
	    ex   de, hl
	    ld   d, a
	    ld   e, (hl)
	    push de
	    inc  hl
	    ld   d, (hl)
	    inc  hl
	    ld   e, (hl)
	    push de
	    exx
	    pop  de
	    pop  hl
	    pop  bc
	    exx
	    inc  hl
	    ld   d, (hl)
	    inc  hl
	    ld   e, (hl)
	    pop  af
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; SHIFT-FP ($2FDD) / ADD-BACK ($3004)
	; ---------------------------------------------------------------------------
L2FDD:
	    and  a
	    ret  z
	    cp   $21
	    jr   nc, L2FF9
	    push bc
	    ld   b, a
L2FE5:
	    exx
	    sra  l
	    rr   d
	    rr   e
	    exx
	    rr   d
	    rr   e
	    djnz L2FE5
	    pop  bc
	    ret  nc
	    call L3004
	    ret  nz
L2FF9:
	    exx
	    xor  a
L2FFB:
	    ld   l, 0
	    ld   d, a
	    ld   e, l
	    exx
	    ld   de, 0
	    ret
L3004:
	    inc  e
	    ret  nz
	    inc  d
	    ret  nz
	    exx
	    inc  e
	    jr   nz, L300D
	    inc  d
L300D:
	    exx
	    ret
	; ---------------------------------------------------------------------------
	; subtract (literal $03, $300F) / addition (literal $0F, $3014)
	; ---------------------------------------------------------------------------
L300F:
	    ex   de, hl
	    call L346E
	    ex   de, hl
L3014:
	    ld   a, (de)
	    or   (hl)
	    jr   nz, L303E
	    push de
	    inc  hl
	    push hl
	    inc  hl
	    ld   e, (hl)
	    inc  hl
	    ld   d, (hl)
	    inc  hl
	    inc  hl
	    inc  hl
	    ld   a, (hl)
	    inc  hl
	    ld   c, (hl)
	    inc  hl
	    ld   b, (hl)
	    pop  hl
	    ex   de, hl
	    add  hl, bc
	    ex   de, hl
	    adc  a, (hl)
	    rrca
	    adc  a, 0
	    jr   nz, L303C
	    sbc  a, a
	    ld   (hl), a
	    inc  hl
	    ld   (hl), e
	    inc  hl
	    ld   (hl), d
	    dec  hl
	    dec  hl
	    dec  hl
	    pop  de
	    ret
L303C:
	    dec  hl
	    pop  de
L303E:
	    call L3293
	    exx
	    push hl
	    exx
	    push de
	    push hl
	    call L2F9B
	    ld   b, a
	    ex   de, hl
	    call L2F9B
	    ld   c, a
	    cp   b
	    jr   nc, L3055
	    ld   a, b
	    ld   b, c
	    ex   de, hl
L3055:
	    push af
	    sub  b
	    call L2FBA
	    call L2FDD
	    pop  af
	    pop  hl
	    ld   (hl), a
	    push hl
	    ld   l, b
	    ld   h, c
	    add  hl, de
	    exx
	    ex   de, hl
	    adc  hl, bc
	    ex   de, hl
	    ld   a, h
	    adc  a, l
	    ld   l, a
	    rra
	    xor  l
	    exx
	    ex   de, hl
	    pop  hl
	    rra
	    jr   nc, L307C
	    ld   a, 1
	    call L2FDD
	    inc  (hl)
	    jr   z, L309F
L307C:
	    exx
	    ld   a, l
	    and  $80
	    exx
	    inc  hl
	    ld   (hl), a
	    dec  hl
	    jr   z, L30A5
	    ld   a, e
	    neg
	    ccf
	    ld   e, a
	    ld   a, d
	    cpl
	    adc  a, 0
	    ld   d, a
	    exx
	    ld   a, e
	    cpl
	    adc  a, 0
	    ld   e, a
	    ld   a, d
	    cpl
	    adc  a, 0
	    jr   nc, L30A3
	    rra
	    exx
	    inc  (hl)
L309F:
	    jp   z, L31AD
	    exx
L30A3:
	    ld   d, a
	    exx
L30A5:
	    xor  a
	    jp   L3155
	; ---------------------------------------------------------------------------
	; HL-HL*DE ($30A9) / PREP-M/D ($30C0)
	; ---------------------------------------------------------------------------
L30A9:
	    push bc
	    ld   b, 16
	    ld   a, h
	    ld   c, l
	    ld   hl, 0
L30B1:
	    add  hl, hl
	    jr   c, L30BE
	    rl   c
	    rla
	    jr   nc, L30BC
	    add  hl, de
	    jr   c, L30BE
L30BC:
	    djnz L30B1
L30BE:
	    pop  bc
	    ret
L30C0:
	    call L34E9
	    ret  c
	    inc  hl
	    xor  (hl)
	    set  7, (hl)
	    dec  hl
	    ret
	; ---------------------------------------------------------------------------
	; multiply (literal $04, $30CA)
	; ---------------------------------------------------------------------------
L30CA:
	    ld   a, (de)
	    or   (hl)
	    jr   nz, L30F0
	    push de
	    push hl
	    push de
	    call L2D7F
	    ex   de, hl
	    ex   (sp), hl
	    ld   b, c
	    call L2D7F
	    ld   a, b
	    xor  c
	    ld   c, a
	    pop  hl
	    call L30A9
	    ex   de, hl
	    pop  hl
	    jr   c, L30EF
	    ld   a, d
	    or   e
	    jr   nz, L30EA
	    ld   c, a
L30EA:
	    call L2D8E
	    pop  de
	    ret
L30EF:
	    pop  de
L30F0:
	    call L3293
	    xor  a
	    call L30C0
	    ret  c
	    exx
	    push hl
	    exx
	    push de
	    ex   de, hl
	    call L30C0
	    ex   de, hl
	    jr   c, L315D
	    push hl
	    call L2FBA
	    ld   a, b
	    and  a
	    sbc  hl, hl
	    exx
	    push hl
	    sbc  hl, hl
	    exx
	    ld   b, $21
	    jr   L3125
L3114:
	    jr   nc, L311B
	    add  hl, de
	    exx
	    adc  hl, de
	    exx
L311B:
	    exx
	    rr   h
	    rr   l
	    exx
	    rr   h
	    rr   l
L3125:
	    exx
	    rr   b
	    rr   c
	    exx
	    rr   c
	    rra
	    djnz L3114
	    ex   de, hl
	    exx
	    ex   de, hl
	    exx
	    pop  bc
	    pop  hl
	    ld   a, b
	    add  a, c
	    jr   nz, L313B
	    and  a
L313B:
	    dec  a
	    ccf
L313D:
	    rla
	    ccf
	    rra
	    jp   p, L3146
	    jr   nc, L31AD
	    and  a
L3146:
	    inc  a
	    jr   nz, L3151
	    jr   c, L3151
	    exx
	    bit  7, d
	    exx
	    jr   nz, L31AD
L3151:
	    ld   (hl), a
	    exx
	    ld   a, b
	    exx
L3155:
	    jr   nc, L316C
	    ld   a, (hl)
	    and  a
L3159:
	    ld   a, $80
	    jr   z, L315E
L315D:
	    xor  a
L315E:
	    exx
	    and  d
	    call L2FFB
	    rlca
	    ld   (hl), a
	    jr   c, L3195
	    inc  hl
	    ld   (hl), a
	    dec  hl
	    jr   L3195
L316C:
	    ld   b, $20
L316E:
	    exx
	    bit  7, d
	    exx
	    jr   nz, L3186
	    rlca
	    rl   e
	    rl   d
	    exx
	    rl   e
	    rl   d
	    exx
	    dec  (hl)
	    jr   z, L3159
	    djnz L316E
	    jr   L315D
L3186:
	    rla
	    jr   nc, L3195
	    call L3004
	    jr   nz, L3195
	    exx
	    ld   d, $80
	    exx
	    inc  (hl)
	    jr   z, L31AD
L3195:
	    push hl
	    inc  hl
	    exx
	    push de
	    exx
	    pop  bc
	    ld   a, b
	    rla
	    rl   (hl)
	    rra
	    ld   (hl), a
	    inc  hl
	    ld   (hl), c
	    inc  hl
	    ld   (hl), d
	    inc  hl
	    ld   (hl), e
	    pop  hl
	    pop  de
	    exx
	    pop  hl
	    exx
	    ret
L31AD:
	    ld   a, ERROR_NumberTooBig
	    jp   __ERROR
	; ---------------------------------------------------------------------------
	; division (literal $05, $31AF)
	; ---------------------------------------------------------------------------
L31AF:
	    call L3293
	    ex   de, hl
	    xor  a
	    call L30C0
	    jr   c, L31AD
	    ex   de, hl
	    call L30C0
	    ret  c
	    exx
	    push hl
	    exx
	    push de
	    push hl
	    call L2FBA
	    exx
	    push hl
	    ld   h, b
	    ld   l, c
	    exx
	    ld   h, c
	    ld   l, b
	    xor  a
	    ld   b, $DF
	    jr   L31E2
L31D2:
	    rla
	    rl   c
	    exx
	    rl   c
	    rl   b
	    exx
L31DB:
	    add  hl, hl
	    exx
	    adc  hl, hl
	    exx
	    jr   c, L31F2
L31E2:
	    sbc  hl, de
	    exx
	    sbc  hl, de
	    exx
	    jr   nc, L31F9
	    add  hl, de
	    exx
	    adc  hl, de
	    exx
	    and  a
	    jr   L31FA
L31F2:
	    and  a
	    sbc  hl, de
	    exx
	    sbc  hl, de
	    exx
L31F9:
	    scf
L31FA:
	    inc  b
	    jp   m, L31D2
	    push af
	    jr   z, L31E2
	    ld   e, a
	    ld   d, c
	    exx
	    ld   e, c
	    ld   d, b
	    pop  af
	    rr   b
	    pop  af
	    rr   b
	    exx
	    pop  bc
	    pop  hl
	    ld   a, b
	    sub  c
	    jp   L313D
	; ---------------------------------------------------------------------------
	; Integer truncation towards zero (literal $3A, $3214)
	; ---------------------------------------------------------------------------
L3214:
	    ld   a, (hl)
	    and  a
	    ret  z
	    cp   $81
	    jr   nc, L3221
	    ld   (hl), 0
	    ld   a, $20
	    jr   L3272
L3221:
	    cp   $91
	    jr   nz, L323F
	    inc  hl
	    inc  hl
	    inc  hl
	    ld   a, $80
	    and  (hl)
	    dec  hl
	    or   (hl)
	    dec  hl
	    jr   nz, L3233
	    ld   a, $80
	    xor  (hl)
L3233:
	    dec  hl
	    jr   nz, L326C
	    ld   (hl), a
	    inc  hl
	    ld   (hl), $FF
	    dec  hl
	    ld   a, $18
	    jr   L3272
L323F:
	    jr   nc, L326D
	    push de
	    cpl
	    add  a, $91
	    inc  hl
	    ld   d, (hl)
	    inc  hl
	    ld   e, (hl)
	    dec  hl
	    dec  hl
	    ld   c, 0
	    bit  7, d
	    jr   z, L3252
	    dec  c
L3252:
	    set  7, d
	    ld   b, 8
	    sub  b
	    add  a, b
	    jr   c, L325E
	    ld   e, d
	    ld   d, 0
	    sub  b
L325E:
	    jr   z, L3267
	    ld   b, a
L3261:
	    srl  d
	    rr   e
	    djnz L3261
L3267:
	    call L2D8E
	    pop  de
	    ret
L326C:
	    ld   a, (hl)
L326D:
	    sub  $A0
	    ret  p
	    neg
L3272:
	    push de
	    ex   de, hl
	    dec  hl
	    ld   b, a
	    srl  b
	    srl  b
	    srl  b
	    jr   z, L3283
L327E:
	    ld   (hl), 0
	    dec  hl
	    djnz L327E
L3283:
	    and  $07
	    jr   z, L3290
	    ld   b, a
	    ld   a, $FF
L328A:
	    sla  a
	    djnz L328A
	    and  (hl)
	    ld   (hl), a
L3290:
	    ex   de, hl
	    pop  de
	    ret
	; ---------------------------------------------------------------------------
	; RE-ST-TWO ($3293) / RESTK-SUB ($3296) / re-stack (literal $3D, $3297)
	; ---------------------------------------------------------------------------
L3293:
	    call L3296
L3296:
	    ex   de, hl
L3297:
	    ld   a, (hl)
	    and  a
	    ret  nz
	    push de
	    call L2D7F
	    xor  a
	    inc  hl
	    ld   (hl), a
	    dec  hl
	    ld   (hl), a
	    ld   b, $91
	    ld   a, d
	    and  a
	    jr   nz, L32B1
	    or   e
	    ld   b, d
	    jr   z, L32BD
	    ld   d, e
	    ld   e, b
	    ld   b, $89
L32B1:
	    ex   de, hl
L32B2:
	    dec  b
	    add  hl, hl
	    jr   nc, L32B2
	    rrc  c
	    rr   h
	    rr   l
	    ex   de, hl
L32BD:
	    dec  hl
	    ld   (hl), e
	    dec  hl
	    ld   (hl), d
	    dec  hl
	    ld   (hl), b
	    pop  de
	    ret
	; ---------------------------------------------------------------------------
	; THE 'TABLE OF CONSTANTS' ($32C5-$32D6)
	; ---------------------------------------------------------------------------
L32C5:  ;;stk-zero
	    defb $00, $B0, $00
L32C8:  ;;stk-one
	    defb $40, $B0, $00, $01
L32CC:  ;;stk-half
	    defb $30, $00
L32CE:  ;;stk-pi/2
	    defb $F1, $49, $0F, $DA, $A2
L32D3:  ;;stk-ten
	    defb $40, $B0, $00, $0A
	; ---------------------------------------------------------------------------
	; THE 'TABLE OF ADDRESSES' ($32D7) — tbl-addrs
	;
	; Las entradas para funciones no soportadas (cadenas, USR, PEEK, IN, CODE,
	; LEN, READ-IN, VAL$) apuntan a CALC_UNSUPPORTED, que detiene la ejecucion
	; con un error claro si alguna vez se generase ese literal (no deberia
; ocurrir: el compilador de ZX BASIC no emite esos literales para nuestro
	; runtime, ver la lista de literales usados en arith/cmp/bool/math/*.asm).
	; ---------------------------------------------------------------------------
L32D7:
	    defw L368F         ; $00 jump-true
	    defw L343C         ; $01 exchange
	    defw L33A1         ; $02 delete
	    defw L300F         ; $03 subtract
	    defw L30CA         ; $04 multiply
	    defw L31AF         ; $05 division
	    defw L3851          ; $06 to-power
	    defw L351B         ; $07 or
	    defw L3524         ; $08 no-&-no
	    defw L353B         ; $09 no-l-eql
	    defw L353B         ; $0A no-gr-eql
	    defw L353B         ; $0B nos-neql
	    defw L353B         ; $0C no-grtr
	    defw L353B         ; $0D no-less
	    defw L353B         ; $0E nos-eql
	    defw L3014         ; $0F addition
	    defw CALC_UNSUPPORTED ; $10 str-&-no
	    defw CALC_UNSUPPORTED ; $11 str-l-eql
	    defw CALC_UNSUPPORTED ; $12 str-gr-eql
	    defw CALC_UNSUPPORTED ; $13 strs-neql
	    defw CALC_UNSUPPORTED ; $14 str-grtr
	    defw CALC_UNSUPPORTED ; $15 str-less
	    defw CALC_UNSUPPORTED ; $16 strs-eql
	    defw CALC_UNSUPPORTED ; $17 strs-add
	    defw CALC_UNSUPPORTED ; $18 val$
	    defw CALC_UNSUPPORTED ; $19 usr-$
	    defw CALC_UNSUPPORTED ; $1A read-in
	    defw L346E          ; $1B negate
	    defw CALC_UNSUPPORTED ; $1C code
    defw CALC_UNSUPPORTED ; $1D val (pendiente: parseo numerico propio)
	    defw CALC_UNSUPPORTED ; $1E len
	    defw L37B5          ; $1F sin
	    defw L37AA          ; $20 cos
	    defw L37DA          ; $21 tan
	    defw L3833          ; $22 asn
	    defw L3843          ; $23 acs
	    defw L37E2          ; $24 atn
	    defw L3713          ; $25 ln
	    defw L36C4          ; $26 exp
	    defw L36AF          ; $27 int
	    defw L384A          ; $28 sqr
	    defw L3492          ; $29 sgn
	    defw L346A          ; $2A abs
	    defw CALC_UNSUPPORTED ; $2B peek
	    defw CALC_UNSUPPORTED ; $2C in
	    defw CALC_UNSUPPORTED ; $2D usr-no
	    defw CALC_UNSUPPORTED ; $2E str$ (pendiente)
	    defw CALC_UNSUPPORTED ; $2F chr$
	    defw L3501          ; $30 not
	    defw L33C0          ; $31 duplicate
	    defw L36A0          ; $32 n-mod-m
	    defw L3686          ; $33 jump
	    defw L33C6          ; $34 stk-data
	    defw L367A          ; $35 dec-jr-nz
	    defw L3506          ; $36 less-0
	    defw L34F9          ; $37 greater-0
	    defw L369B          ; $38 end-calc
	    defw L3783          ; $39 get-argt
	    defw L3214          ; $3A truncate
	    defw L33A2          ; $3B fp-calc-2
	    defw CALC_UNSUPPORTED ; $3C e-to-fp
	    defw L3297          ; $3D re-stack
	    defw L3449          ; series-xx    $80-$9F
	    defw L341B          ; stk-const-xx $A0-$BF
	    defw L342D          ; st-mem-xx    $C0-$DF
	    defw L340F          ; get-mem-xx   $E0-$FF
CALC_UNSUPPORTED:
	    ld   a, ERROR_InvalidArg
	    jp   __ERROR
	; ---------------------------------------------------------------------------
	; THE 'CALCULATE' SUBROUTINE ($335B) — motor principal
	; ---------------------------------------------------------------------------
L335B:
	    call L35BF
L335E:
	    ld   a, b
	    ld   (FP_BREG), a
L3362:
	    exx
	    ex   (sp), hl
	    exx
L3365:
	    ld   (FP_STKEND), de
	    exx
	    ld   a, (hl)
	    inc  hl
L336C:
	    push hl
	    and  a
	    jp   p, L3380
	    ld   d, a
	    and  $60
	    rrca
	    rrca
	    rrca
	    rrca
	    add  a, $7C
	    ld   l, a
	    ld   a, d
	    and  $1F
	    jr   L338E
L3380:
	    cp   $18
	    jr   nc, L338C
	    exx
	    ld   bc, $FFFB
	    ld   d, h
	    ld   e, l
	    add  hl, bc
	    exx
L338C:
	    rlca
	    ld   l, a
L338E:
	    ld   de, L32D7
	    ld   h, 0
	    add  hl, de
	    ld   e, (hl)
	    inc  hl
	    ld   d, (hl)
	    ld   hl, L3365
	    ex   (sp), hl
	    push de
	    exx
	    ld   bc, (FP_STKEND + 1)    ; C=STKEND_hi, B=FP_BREG (ver nota en sysvars.asm)
	    ret
	; ---------------------------------------------------------------------------
	; delete (literal $02) — un simple RET; tambien destino de salto indirecto
	; ---------------------------------------------------------------------------
L33A1:
	    ret
	; ---------------------------------------------------------------------------
	; fp-calc-2 (literal $3B) — reentrada de un solo literal
	; ---------------------------------------------------------------------------
L33A2:
	    pop  af
	    ld   a, (FP_BREG)
	    exx
	    jr   L336C
	; ---------------------------------------------------------------------------
	; STK-PNTRS ($35BF)
	; ---------------------------------------------------------------------------
L35BF:
	    ld   hl, (FP_STKEND)
	    ld   de, $FFFB
	    push hl
	    add  hl, de
	    pop  de
	    ret
	; ---------------------------------------------------------------------------
	; jump-true (literal $00) / jump (literal $33) / dec-jr-nz (literal $35)
	; ---------------------------------------------------------------------------
L368F:
	    inc  de
	    inc  de
	    ld   a, (de)
	    dec  de
	    dec  de
	    and  a
	    jr   nz, L3686
	    exx
	    inc  hl
	    exx
	    ret
L367A:
	    exx
	    push hl
	    ld   hl, FP_BREG
	    dec  (hl)
	    pop  hl
	    jr   nz, L3687
	    inc  hl
	    exx
	    ret
L3686:
	    exx
L3687:
	    ld   e, (hl)
	    ld   a, e
	    rla
	    sbc  a, a
	    ld   d, a
	    add  hl, de
	    exx
	    ret
	; ---------------------------------------------------------------------------
	; end-calc (literal $38)
	; ---------------------------------------------------------------------------
L369B:
	    pop  af
	    exx
	    ex   (sp), hl
	    exx
	    ret
	; ---------------------------------------------------------------------------
	; n-mod-m (literal $32) — implementado como programa del propio calculador
	; ---------------------------------------------------------------------------
L36A0:
	    rst  28h
	    defb $C0, $02, $31, $E0, $05, $27, $E0, $01, $C0, $04, $03, $E0, $38
	    ret
	; ---------------------------------------------------------------------------
	; int (literal $27) — implementado como programa del propio calculador
	; ---------------------------------------------------------------------------
L36AF:
	    rst  28h
	    defb $31            ;;duplicate
	    defb $36            ;;less-0
	    defb $00            ;;jump-true
	    defb (L36B7 - $) & 0FFh  ;;a X-NEG
	    defb $3A            ;;truncate
	    defb $38            ;;end-calc
	    ret
L36B7:
	    defb $31            ;;duplicate
	    defb $3A            ;;truncate
	    defb $C0            ;;st-mem-0
	    defb $03            ;;subtract
	    defb $E0            ;;get-mem-0
	    defb $01            ;;exchange
	    defb $30            ;;not
	    defb $00            ;;jump-true
	    defb (L36C2 - $) & 0FFh  ;;a EXIT
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
L36C2:
	    defb $38            ;;end-calc
	; ---------------------------------------------------------------------------
	; TEST-ZERO ($34E9) / GREATER-0 (literal $37) / NOT (literal $30) /
	; less-0 (literal $36) / SIGN-TO-C / FP-0/1
	; ---------------------------------------------------------------------------
L34E9:
	    push hl
	    push bc
	    ld   b, a
	    ld   a, (hl)
	    inc  hl
	    or   (hl)
	    inc  hl
	    or   (hl)
	    inc  hl
	    or   (hl)
	    ld   a, b
	    pop  bc
	    pop  hl
	    ret  nz
	    scf
	    ret
L34F9:
	    call L34E9
	    ret  c
	    ld   a, $FF
	    jr   L3507
L3501:
	    call L34E9
	    jr   L350B
L3506:
	    xor  a
L3507:
	    inc  hl
	    xor  (hl)
	    dec  hl
	    rlca
L350B:
	    push hl
	    ld   a, 0
	    ld   (hl), a
	    inc  hl
	    ld   (hl), a
	    inc  hl
	    rla
	    ld   (hl), a
	    rra
	    inc  hl
	    ld   (hl), a
	    inc  hl
	    ld   (hl), a
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; or (literal $07) / no-&-no (literal $08)
	; ---------------------------------------------------------------------------
L351B:
	    ex   de, hl
	    call L34E9
	    ex   de, hl
	    ret  c
	    scf
	    jr   L350B
L3524:
	    ex   de, hl
	    call L34E9
	    ex   de, hl
	    ret  nc
	    and  a
	    jr   L350B
	; ---------------------------------------------------------------------------
	; comparaciones numericas (literales $09-$0E, $353B) — solo la rama numerica;
	; no se soportan comparaciones de cadenas via calculador en este runtime.
	; ---------------------------------------------------------------------------
L353B:
	    ld   a, b
	    sub  8
	    bit  2, a
	    jr   nz, L3543
	    dec  a
L3543:
	    rrca
	    jr   nc, L354E
	    push af
	    push hl
	    call L343C
	    pop  de
	    ex   de, hl
	    pop  af
L354E:
	    rrca
	    push af
	    call L300F
	    jr   L358C
	; ---------------------------------------------------------------------------
	; END-TESTS ($358C)
	; ---------------------------------------------------------------------------
L358C:
	    pop  af
	    push af
	    call c, L3501
	    pop  af
	    push af
	    call nc, L34F9
	    pop  af
	    rrca
	    call nc, L3501
	    ret
	; ===========================================================================
; FASE 4: SIN/COS/TAN/ASN/ACS/ATN/LN/EXP/SQR
	;
	; Todas estas funciones son, igual que "int" o "n-mod-m" mas arriba,
	; programas del propio calculador (rst 28h + bytes de literal), identicos a
	; los de la ROM, apoyados en el "series generator" (L3449/L3453) ya portado.
	; Solo se han corregido los offsets de jump-true/jump (recalculados con la
; misma formula ya usada en el resto del fichero: (destino - $) & 0FFh) y se
	; ha sustituido "RST 08h ; DEFB <codigo>" (ERROR-1 de la ROM) por el
	; mecanismo de error propio (ERROR_xxx + jp __ERROR).
	; ===========================================================================
	; ---------------------------------------------------------------------------
	; STACK-A ($2D28) / STACK-BC ($2D2B) — apila A (o BC) como entero pequeño
	; ---------------------------------------------------------------------------
L2D28:
	    ld   c, a
	    ld   b, 0
L2D2B:
	    xor  a
	    ld   e, a
	    ld   d, c
	    ld   c, b
	    ld   b, a
	    call __FPSTACK_PUSH
	    rst  28h
	    defb $38            ;;end-calc (recalcula HL/DE tras el push)
	    and  a
	    ret
	; ---------------------------------------------------------------------------
	; FP-TO-BC ($2DA2) — recoge el ultimo valor de la pila FP en BC (redondeando)
	; ---------------------------------------------------------------------------
L2DA2:
	    rst  28h
	    defb $38            ;;end-calc -> HL apunta al ultimo valor
	    ld   a, (hl)
	    and  a
	    jr   z, L2DAD
	    rst  28h
	    defb $A2            ;;stk-half
	    defb $0F            ;;addition
	    defb $27            ;;int
	    defb $38            ;;end-calc
L2DAD:
	    rst  28h
	    defb $02            ;;delete
	    defb $38            ;;end-calc
	    push hl
	    push de
	    ex   de, hl
	    ld   b, (hl)
	    call L2D7F
	    xor  a
	    sub  b
	    bit  7, c
	    ld   b, d
	    ld   c, e
	    ld   a, e
	    pop  de
	    pop  hl
	    ret
	; ---------------------------------------------------------------------------
	; FP-TO-A ($2DD5) — como FP-TO-BC pero devuelve A, con overflow en carry
	; ---------------------------------------------------------------------------
L2DD5:
	    call L2DA2
	    ret  c
	    push af
	    dec  b
	    inc  b
	    jr   z, L2DE1
	    pop  af
	    scf
	    ret
L2DE1:
	    pop  af
	    ret
	; ---------------------------------------------------------------------------
	; get-argt (literal $39, $3783) — reduce el argumento de sin/cos a -1..+1
	; ---------------------------------------------------------------------------
L3783:
	    rst  28h
	    defb $3D            ;;re-stack
	    defb $34            ;;stk-data
    defb $EE            ;;Exponent: $7E, Bytes: 4
	    defb $22, $F9, $83, $6E
	    defb $04            ;;multiply
	    defb $31            ;;duplicate
	    defb $A2            ;;stk-half
	    defb $0F            ;;addition
	    defb $27            ;;int
	    defb $03            ;;subtract
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $31            ;;duplicate
	    defb $2A            ;;abs
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $31            ;;duplicate
	    defb $37            ;;greater-0
	    defb $C0            ;;st-mem-0
	    defb $00            ;;jump-true
	    defb (L37A1 - $) & 0FFh    ;;a ZPLUS
	    defb $02            ;;delete
	    defb $38            ;;end-calc
	    ret
L37A1:
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $01            ;;exchange
	    defb $36            ;;less-0
	    defb $00            ;;jump-true
	    defb (L37A8 - $) & 0FFh    ;;a YNEG
	    defb $1B            ;;negate
L37A8:
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; cos (literal $20, $37AA) — cae en sin/C-ENT (codigo compartido)
	; ---------------------------------------------------------------------------
L37AA:
	    rst  28h
	    defb $39            ;;get-argt
	    defb $2A            ;;abs
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $E0            ;;get-mem-0
	    defb $00            ;;jump-true
	    defb (L37B7 - $) & 0FFh    ;;a C-ENT
	    defb $1B            ;;negate
	    defb $33            ;;jump
	    defb (L37B7 - $) & 0FFh    ;;a C-ENT
	; ---------------------------------------------------------------------------
	; sin (literal $1F, $37B5) / C-ENT ($37B7, compartido con cos)
	; ---------------------------------------------------------------------------
L37B5:
	    rst  28h
	    defb $39            ;;get-argt
L37B7:
	    defb $31            ;;duplicate
	    defb $31            ;;duplicate
	    defb $04            ;;multiply
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $86            ;;series-06
	    defb $14, $E6
	    defb $5C, $1F, $0B
	    defb $A3, $8F, $38, $EE
	    defb $E9, $15, $63, $BB, $23
	    defb $EE, $92, $0D, $CD, $ED
	    defb $F1, $23, $5D, $1B, $EA
	    defb $04            ;;multiply
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; tan (literal $21, $37DA) — sin(x) / cos(x)
	; ---------------------------------------------------------------------------
L37DA:
	    rst  28h
	    defb $31            ;;duplicate
	    defb $1F            ;;sin
	    defb $01            ;;exchange
	    defb $20            ;;cos
	    defb $05            ;;division
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; atn (literal $24, $37E2)
	; ---------------------------------------------------------------------------
L37E2:
	    call L3297          ; re-stack
	    ld   a, (hl)
	    cp   $81
	    jr   c, L37F8       ; SMALL
	    rst  28h
	    defb $A1            ;;stk-one
	    defb $1B            ;;negate
	    defb $01            ;;exchange
	    defb $05            ;;division
	    defb $31            ;;duplicate
	    defb $36            ;;less-0
	    defb $A3            ;;stk-pi/2
	    defb $01            ;;exchange
	    defb $00            ;;jump-true
	    defb (L37FA - $) & 0FFh    ;;a CASES
	    defb $1B            ;;negate
	    defb $33            ;;jump
	    defb (L37FA - $) & 0FFh    ;;a CASES
L37F8:
	    rst  28h
	    defb $A0            ;;stk-zero
L37FA:
	    defb $01            ;;exchange
	    defb $31            ;;duplicate
	    defb $31            ;;duplicate
	    defb $04            ;;multiply
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $8C            ;;series-0C
	    defb $10, $B2
	    defb $13, $0E
	    defb $55, $E4, $8D
	    defb $58, $39, $BC
	    defb $5B, $98, $FD
	    defb $9E, $00, $36, $75
	    defb $A0, $DB, $E8, $B4
	    defb $63, $42, $C4
	    defb $E6, $B5, $09, $36, $BE
	    defb $E9, $36, $73, $1B, $5D
	    defb $EC, $D8, $DE, $63, $BE
	    defb $F0, $61, $A1, $B3, $0C
	    defb $04            ;;multiply
	    defb $0F            ;;addition
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; asn (literal $22, $3833)
	; ---------------------------------------------------------------------------
L3833:
	    rst  28h
	    defb $31            ;;duplicate
	    defb $31            ;;duplicate
	    defb $04            ;;multiply
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $1B            ;;negate
	    defb $28            ;;sqr
	    defb $A1            ;;stk-one
	    defb $0F            ;;addition
	    defb $05            ;;division
	    defb $24            ;;atn
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; acs (literal $23, $3843)
	; ---------------------------------------------------------------------------
L3843:
	    rst  28h
	    defb $22            ;;asn
	    defb $A3            ;;stk-pi/2
	    defb $03            ;;subtract
	    defb $1B            ;;negate
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; ln (literal $25, $3713)
	; ---------------------------------------------------------------------------
L3713:
	    rst  28h
	    defb $3D            ;;re-stack
	    defb $31            ;;duplicate
	    defb $37            ;;greater-0
	    defb $00            ;;jump-true
	    defb (L371C - $) & 0FFh    ;;a VALID
	    defb $38            ;;end-calc
	    ld   a, ERROR_InvalidArg
	    jp   __ERROR
L371C:
	    defb $A0            ;;stk-zero
	    defb $02            ;;delete
	    defb $38            ;;end-calc
	    ld   a, (hl)
	    ld   (hl), $80
	    call L2D28
	    rst  28h
	    defb $34            ;;stk-data
    defb $38            ;;Exponent: $88, Bytes: 1
	    defb $00
	    defb $03            ;;subtract
	    defb $01            ;;exchange
	    defb $31            ;;duplicate
	    defb $34            ;;stk-data
    defb $F0            ;;Exponent: $80, Bytes: 4
	    defb $4C, $CC, $CC, $CD
	    defb $03            ;;subtract
	    defb $37            ;;greater-0
	    defb $00            ;;jump-true
	    defb (L373D - $) & 0FFh    ;;a GRE.8
	    defb $01            ;;exchange
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $01            ;;exchange
	    defb $38            ;;end-calc
	    inc  (hl)
	    rst  28h
L373D:
	    defb $01            ;;exchange
	    defb $34            ;;stk-data
    defb $F0            ;;Exponent: $80, Bytes: 4
	    defb $31, $72, $17, $F8
	    defb $04            ;;multiply
	    defb $01            ;;exchange
	    defb $A2            ;;stk-half
	    defb $03            ;;subtract
	    defb $A2            ;;stk-half
	    defb $03            ;;subtract
	    defb $31            ;;duplicate
	    defb $34            ;;stk-data
    defb $32            ;;Exponent: $82, Bytes: 1
	    defb $20
	    defb $04            ;;multiply
	    defb $A2            ;;stk-half
	    defb $03            ;;subtract
	    defb $8C            ;;series-0C
	    defb $11, $AC
	    defb $14, $09
	    defb $56, $DA, $A5
	    defb $59, $30, $C5
	    defb $5C, $90, $AA
	    defb $9E, $70, $6F, $61
	    defb $A1, $CB, $DA, $96
	    defb $A4, $31, $9F, $B4
	    defb $E7, $A0, $FE, $5C, $FC
	    defb $EA, $1B, $43, $CA, $36
	    defb $ED, $A7, $9C, $7E, $5E
	    defb $F0, $6E, $23, $80, $93
	    defb $04            ;;multiply
	    defb $0F            ;;addition
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; exp (literal $26, $36C4)
	; ---------------------------------------------------------------------------
L36C4:
	    rst  28h
	    defb $3D            ;;re-stack
	    defb $34            ;;stk-data
    defb $F1            ;;Exponent: $81, Bytes: 4
	    defb $38, $AA, $3B, $29
	    defb $04            ;;multiply
	    defb $31            ;;duplicate
	    defb $27            ;;int
	    defb $C3            ;;st-mem-3
	    defb $03            ;;subtract
	    defb $31            ;;duplicate
	    defb $0F            ;;addition
	    defb $A1            ;;stk-one
	    defb $03            ;;subtract
	    defb $88            ;;series-08
	    defb $13, $36
	    defb $58, $65, $66
	    defb $9D, $78, $65, $40
	    defb $A2, $60, $32, $C9
	    defb $E7, $21, $F7, $AF, $24
	    defb $EB, $2F, $B0, $B0, $14
	    defb $EE, $7E, $BB, $94, $58
	    defb $F1, $3A, $7E, $F8, $CF
	    defb $E3            ;;get-mem-3
	    defb $38            ;;end-calc
	    call L2DD5
	    jr   nz, L3705      ; N-NEGTV
	    jr   c, L3703       ; REPORT-6b
	    add  a, (hl)
	    jr   nc, L370C      ; RESULT-OK
L3703:
	    ld   a, ERROR_NumberTooBig
	    jp   __ERROR
L3705:
	    jr   c, L370E       ; RSLT-ZERO
	    sub  (hl)
	    jr   nc, L370E      ; RSLT-ZERO
	    neg
L370C:
	    ld   (hl), a
	    ret
L370E:
	    rst  28h
	    defb $02            ;;delete
	    defb $A0            ;;stk-zero
	    defb $38            ;;end-calc
	    ret
	; ---------------------------------------------------------------------------
	; sqr (literal $28, $384A) — cae en to-power (codigo compartido)
	; ---------------------------------------------------------------------------
L384A:
	    rst  28h
	    defb $31            ;;duplicate
	    defb $30            ;;not
	    defb $00            ;;jump-true
	    defb (L386C - $) & 0FFh    ;;a LAST
	    defb $A2            ;;stk-half
	    defb $38            ;;end-calc
	; ---------------------------------------------------------------------------
	; to-power (literal $06, $3851)
	; ---------------------------------------------------------------------------
L3851:
	    rst  28h
	    defb $01            ;;exchange
	    defb $31            ;;duplicate
	    defb $30            ;;not
	    defb $00            ;;jump-true
	    defb (L385D - $) & 0FFh    ;;a XIS0
	    defb $25            ;;ln
	    defb $04            ;;multiply
	    defb $38            ;;end-calc
	    jp   L36C4
L385D:
	    defb $02            ;;delete
	    defb $31            ;;duplicate
	    defb $30            ;;not
	    defb $00            ;;jump-true
	    defb (L386A - $) & 0FFh    ;;a ONE
	    defb $A0            ;;stk-zero
	    defb $01            ;;exchange
	    defb $37            ;;greater-0
	    defb $00            ;;jump-true
	    defb (L386C - $) & 0FFh    ;;a LAST
	    defb $A1            ;;stk-one
	    defb $01            ;;exchange
	    defb $05            ;;division
L386A:
	    defb $02            ;;delete
	    defb $A1            ;;stk-one
L386C:
	    defb $38            ;;end-calc
	    ret
	; ===========================================================================
; FASE 5: STK-TO-A / STK-TO-BC / CD-PRMS1
	;
	; Rutinas auxiliares de la ROM usadas por DRAW3 (modo arco) y CIRCLE-DRAW.
	; No son literales del calculador (no se invocan via rst 28h + defb), sino
	; rutinas normales que a su vez usan el calculador ya portado (FP-TO-A,
	; STACK-A, y los literales sqr/sin/stk-data/etc de fp_calc.asm).
	; ===========================================================================
	; ---------------------------------------------------------------------------
	; STK-TO-A ($2314) — comprime el ultimo valor de la pila FP en A.
	; C = $01 si es positivo o cero, $FF si es negativo.
	; Error IntOutOfRange (sustituye a REPORT-Bc / RST 08h) si >= 256.
	; ---------------------------------------------------------------------------
L2314:
    call L2DD5          ; FP-TO-A: A = valor comprimido, Z si signo positivo
	    jr   c, L24F9
	    ld   c, $01
	    ret  z
	    ld   c, $FF
	    ret
L24F9:
	    ld   a, ERROR_IntOutOfRange
	    jp   __ERROR
	; ---------------------------------------------------------------------------
; STK-TO-BC ($2307) — recoge dos valores de la pila FP: el primero (mas
	; antiguo) en BC, el segundo (mas reciente) en DE (bajo, con signo en E/D).
	; ---------------------------------------------------------------------------
L2307:
	    call L2314
	    ld   b, a
	    push bc
	    call L2314
	    ld   e, c
	    pop  bc
	    ld   d, c
	    ld   c, a
	    ret
	; ---------------------------------------------------------------------------
; CD-PRMS1 ($247D) — CIRCLE/DRAW PARAMETERS: a partir del "diametro" z (tope
	; de pila) y el angulo total en mem-5, calcula el numero de lineas rectas
	; (B, multiplo de 4, max 252) y deja en mem-1/mem-3/mem-4 sin(a/2), cos(a) y
	; sin(a) del angulo de paso "a" = ANGULO/lineas.
	; ---------------------------------------------------------------------------
L247D:
	    rst  28h
	    defb $31            ;;duplicate     z, z.
	    defb $28            ;;sqr           z, sqr(z).
	    defb $34            ;;stk-data      z, sqr(z), 2.
    defb $32            ;;Exponent: $82, Bytes: 1
	    defb $00            ;;(+00,+00,+00)
	    defb $01            ;;exchange      z, 2, sqr(z).
	    defb $05            ;;division      z, 2/sqr(z).
	    defb $E5            ;;get-mem-5     z, 2/sqr(z), ANGLE.
	    defb $01            ;;exchange      z, ANGLE, 2/sqr(z)
	    defb $05            ;;division      z, ANGLE*sqr(z)/2 (=num. lineas)
	    defb $2A            ;;abs           (solo para arco)
	    defb $38            ;;end-calc      z, numero de lineas.
	    call L2DD5          ; FP-TO-A
	    jr   c, L247D_USE252
	    and  $FC            ; multiplo de 4 (p.ej. 29 -> 28)
	    add  a, $04          ; podria dar overflow -> 256
	    jr   nc, L247D_SAVE
L247D_USE252:
	    ld   a, $FC          ; limite de 252 (para arco)
L247D_SAVE:
	    push af              ; conserva el contador de lineas
	    call L2D28           ; apila el contador modificado
	    rst  28h
	    defb $E5            ;;get-mem-5     z, A, ANGLE.
	    defb $01            ;;exchange      z, ANGLE, A.
	    defb $05            ;;division      z, ANGLE/A. (angulo de paso = a)
	    defb $31            ;;duplicate     z, a, a.
	    defb $1F            ;;sin           z, a, sin(a)
	    defb $C4            ;;st-mem-4      z, a, sin(a)
	    defb $02            ;;delete        z, a.
	    defb $31            ;;duplicate     z, a, a.
	    defb $A2            ;;stk-half      z, a, a, 1/2.
	    defb $04            ;;multiply      z, a, a/2.
	    defb $1F            ;;sin           z, a, sin(a/2).
	    defb $C1            ;;st-mem-1      z, a, sin(a/2).
	    defb $01            ;;exchange      z, sin(a/2), a.
	    defb $C0            ;;st-mem-0      z, sin(a/2), a.  (solo para arco)
	    defb $02            ;;delete        z, sin(a/2).
	    defb $31            ;;duplicate     z, sin(a/2), sin(a/2).
	    defb $04            ;;multiply      z, sin(a/2)^2.
	    defb $31            ;;duplicate     z, sin(a/2)^2, sin(a/2)^2.
	    defb $0F            ;;addition      z, 2*sin(a/2)^2.
	    defb $A1            ;;stk-one       z, 2*sin(a/2)^2, 1.
	    defb $03            ;;subtract      z, 2*sin(a/2)^2-1.
	    defb $1B            ;;negate        z, 1-2*sin(a/2)^2 = cos(a).
	    defb $C3            ;;st-mem-3      z, cos(a).
	    defb $02            ;;delete        z.
	    defb $38            ;;end-calc      z.
	    pop  bc              ; restaura el contador de lineas
	    ret
	    pop namespace
#line 21 "/zxbasic/src/lib/arch/zx81sd/runtime/bootstrap.asm"
	    push namespace core
	; SD81_INIT_SYSVARS — Inicializa el bloque de variables del runtime en $8000
SD81_INIT_SYSVARS:
	    PROC
    ; CHARS apunta 256 bytes ANTES del inicio del font (convención Spectrum):
	    ; el runtime calcula glifo = CHARS + código*8, sin restar 32.
	    ; Así CHR$(32)=space → CHARS+256 = font[0], CHR$(72)='H' → CHARS+576 = font[40].
	    ld   hl, __ZX81SD_CHARSET - 256
	    ld   (CHARS), hl
    ; UDG: área dedicada de 21 caracteres definibles (CHR$(144)-CHR$(164),
	    ; como en el Spectrum), reservada en charset.asm DESPUÉS de la fuente.
    ; (La fuente sólo cubre CHR$(32)-CHR$(127): el antiguo "font+896"
	    ; apuntaba 128 bytes más allá de su final, sobre código del runtime,
	    ; y los POKE USR CHR$ de un programa lo corrompían.)
	    ld   hl, __ZX81SD_UDG_AREA
	    ld   (UDG), hl
	    ; Inicializa los UDGs con copias de las letras A-U (como la ROM del
    ; Spectrum): glifo de 'A' = font + (65-32)*8 = font + 264.
	    ld   hl, __ZX81SD_CHARSET + 264
	    ld   de, __ZX81SD_UDG_AREA
	    ld   bc, 21 * 8
	    ldir
	    ; Cursor al inicio de pantalla (columna=SCR_COLS, fila=SCR_ROWS)
	    ld   a, SCR_ROWS
	    ld   h, a
	    ld   a, SCR_COLS
	    ld   l, a
	    ld   (S_POSN), hl
    ; SCREEN_ADDR / SCREEN_ATTR_ADDR son variables RAM (no constantes EQU):
	    ; el runtime las lee con LD HL,(SCREEN_ADDR) para obtener la dirección.
	    ld   hl, $C000
	    ld   (SCREEN_ADDR), hl      ; $801E ← $C000
	    ld   (DFCC), hl             ; cursor bitmap al inicio de pantalla
	    ld   hl, $D800
	    ld   (SCREEN_ATTR_ADDR), hl ; $8020 ← $D800
	    ld   (DFCCL), hl            ; cursor attrs al inicio de atributos
    ; COORDS: último punto PLOT = (0,0)
	    xor  a
	    ld   (COORDS), a
	    ld   (COORDS + 1), a
    ; Atributos por defecto: tinta negra sobre fondo blanco (INK 0, PAPER 7)
	    ; $38 = 0b00111000 = PAPER 7 + INK 0, igual que el defecto del Spectrum
	    ld   a, $38
	    ld   (ATTR_P), a
	    xor  a
	    ld   (MASK_P), a            ; $00 = sin transparencia (COPY_ATTR copia ATTR_P íntegro)
	    ld   hl, $0038              ; ATTR_T=$38, MASK_T=$00
	    ld   (ATTR_T), hl
	    ; Borra la pantalla física (bitmap + atributos). El bloque 6 es RAM
	    ; que sobrevive a un reset (no se limpia sola como al encender una
	    ; ROM real), así que sin esto un programa hereda el contenido que
	    ; dejó el anterior hasta que él mismo llame a CLS.
	    ld   hl, $C000
	    ld   (hl), 0
	    ld   d, h
	    ld   e, l
	    inc  de
	    ld   bc, 6143
	    ldir
	    ld   hl, $D800
	    ld   a, (ATTR_P)
	    ld   (hl), a
	    ld   d, h
	    ld   e, l
	    inc  de
	    ld   bc, 767
	    ldir
	    ; Flags a cero
	    xor  a
	    ld   (FLAGS2), a
	    ld   (P_FLAG), a
	    ld   (TV_FLAG), a
	    ld   (ERR_NR), a
	    ; Contadores a cero
	    ld   hl, 0
	    ld   (FRAMES), hl
	    ld   (RANDOM_SEED_LOW), hl
    ; Calculador de coma flotante (fp_calc.asm): pila FP vacía, MEM en su
	    ; posición por defecto (ver sysvars.asm)
	    ld   hl, FP_CALC_STACK
	    ld   (FP_STKBOT), hl
	    ld   (FP_STKEND), hl
	    ld   hl, FP_MEM_AREA
	    ld   (FP_MEM), hl
	    ret
	    ENDP
	    pop namespace
#line 17 "/zxbasic/src/lib/arch/zx81sd/runtime/sysvars.asm"
	    push namespace core
	; --- Variables dinámicas del runtime ($8000+) ---------------------------
	; Zona de datos (bloques 4-5), no ejecutable sin MC45.
	;
	; SCREEN_ADDR y SCREEN_ATTR_ADDR son variables RAM (no constantes EQU)
; porque el runtime de zx48k las lee con direccionamiento indirecto:
	;   LD HL, (SCREEN_ADDR)  →  carga el CONTENIDO de esa posición de memoria.
	; SD81_INIT_SYSVARS las inicializa con $C000 y $D800 respectivamente.
	SYSVAR_BASE         EQU $8000
	CHARS               EQU SYSVAR_BASE + $00   ; DW  — puntero a charset (8x8)
	UDG                 EQU SYSVAR_BASE + $02   ; DW  — puntero a UDGs
	COORDS              EQU SYSVAR_BASE + $04   ; DW  — última coordenada PLOT (X,Y)
	FLAGS2              EQU SYSVAR_BASE + $06   ; DB  — flags de pantalla (OVER/INVERSE/etc.)
	ECHO_E              EQU SYSVAR_BASE + $07   ; DB  — (reservado)
	DFCC                EQU SYSVAR_BASE + $08   ; DW  — siguiente dirección bitmap para PRINT
	DFCCL               EQU SYSVAR_BASE + $0A   ; DW  — siguiente dirección attrs para PRINT
	S_POSN              EQU SYSVAR_BASE + $0C   ; DW  — posición cursor (H=fila, L=columna)
	ATTR_P              EQU SYSVAR_BASE + $0E   ; DB  — atributo permanente (INK/PAPER/etc.)
	MASK_P              EQU SYSVAR_BASE + $0F   ; DB  — máscara permanente ($00 = sin transparencia)
	ATTR_T              EQU SYSVAR_BASE + $10   ; DB  — atributo temporal
	; MASK_T se accede implícitamente como ATTR_T+1 ($8011) via LD HL,(ATTR_T)
	P_FLAG              EQU SYSVAR_BASE + $12   ; DB  — flags de impresión (OVER/INVERSE perm.)
	MEM0                EQU SYSVAR_BASE + $13   ; 5B  — buffer temporal para rutinas gráficas
	TV_FLAG             EQU SYSVAR_BASE + $18   ; DB  — flags de control de salida a pantalla
	ERR_NR              EQU SYSVAR_BASE + $19   ; DB  — código de error (-1 = sin error)
	FRAMES              EQU SYSVAR_BASE + $1A   ; DW  — contador de frames VSYNC (software)
	RANDOM_SEED_LOW     EQU SYSVAR_BASE + $1C   ; DW  — semilla RNG (16 bits bajos)
SCREEN_ADDR         EQU SYSVAR_BASE + $1E   ; DW  — puntero al framebuffer (init: $C000)
SCREEN_ATTR_ADDR    EQU SYSVAR_BASE + $20   ; DW  — puntero a atributos   (init: $D800)
	; --- Sysvars del calculador de coma flotante (fp_calc.asm) --------------
	; Equivalentes a STKBOT/STKEND/BREG/MEM de la ROM Spectrum ($5C63/$5C65/
	; $5C67/$5C68), pero apuntando a un buffer fijo propio en vez de al área
	; de trabajo dinámica de la ROM (aquí no existe "memoria libre creciente"
	; entre el programa y la pila de máquina).
	;
; IMPORTANTE: FP_BREG debe estar INMEDIATAMENTE DESPUÉS de FP_STKEND — el
	; motor CALCULATE (L338E, ENT-TABLE) explota la contigüidad de memoria de
	; la ROM original (STKEND_hi seguido de BREG) para cargar ambos con un
; único LD BC,(FP_STKEND+1): C=STKEND_hi, B=BREG. No reordenar.
	FP_STKBOT           EQU SYSVAR_BASE + $22   ; DW — base de la pila de números FP
	FP_STKEND           EQU SYSVAR_BASE + $24   ; DW — siguiente posición libre en la pila FP
	FP_BREG             EQU SYSVAR_BASE + $26   ; DB — literal en curso (para fp-calc-2/dec-jr-nz)
	FP_MEM              EQU SYSVAR_BASE + $27   ; DW — puntero al área MEM (6 celdas de 5B)
	FP_CALC_STACK       EQU SYSVAR_BASE + $29   ; 60B — pila de números FP (12 números máx.)
	FP_CALC_STACK_END   EQU FP_CALC_STACK + 60
	FP_MEM_AREA         EQU SYSVAR_BASE + $65   ; 30B — área MEM (6 celdas de 5 bytes)
	; --- Scratch del indexador de arrays (runtime/array/array.asm) ---------
	; El array.asm compartido de zx48k usa la sysvar MEMBOT de la ROM Spectrum
	; (dirección fija 23698 = $5C92) como almacenamiento temporal para sus
	; punteros (LBOUND_PTR/UBOUND_PTR/RET_ADDR/TMP_ARR_PTR, 2 bytes cada uno).
	; En zx81sd esa dirección cae dentro del propio código compilado del
; programa (bloque 2, $4000-$5FFF): cualquier array multidimensional lo
	; corrompía en cada acceso. El override zx81sd de array.asm usa esta
	; zona en su lugar.
	ARRAY_SCRATCH       EQU SYSVAR_BASE + $83   ; 8B — LBOUND/UBOUND/RET/TMP_ARR_PTR
	; --- Scratch de CHR$() (runtime/chr.asm) --------------------------------
	; El chr.asm compartido de zx48k usa la sysvar DEST de la ROM Spectrum
	; (dirección fija 23629 = $5C4D) para guardar temporalmente la dirección
	; de retorno mientras reserva memoria para la cadena. Esa dirección cae
	; dentro del código compilado en zx81sd (bloque 2, en concreto dentro de
	; __DIVU32). El override zx81sd de chr.asm usa esta zona en su lugar.
	CHR_SCRATCH         EQU SYSVAR_BASE + $8B   ; 2B — dirección de retorno
	; --- Scratch de la división FP (runtime/arith/divf.asm) -----------------
	; El divf.asm compartido de zx48k usa DEST (23629, igual que chr.asm) y
	; ERR_SP (23613) de la ROM Spectrum para guardar/restaurar un punto de
	; recuperación de pila alrededor de la división en coma flotante (truco
	; de "longjmp" para división por cero). En zx81sd ese mecanismo de
	; recuperación no llega a usarse de verdad (__ERROR hace DI+HALT
	; directamente, no restaura SP desde ERR_SP), pero el código escribe ahí
	; en TODAS las divisiones igualmente, no solo cuando hay error — y esas
	; direcciones caen dentro del código compilado (bloque 2). El override
	; zx81sd usa esta zona en su lugar (mismo mecanismo, solo cambia dónde
	; vive el scratch).
	DIVF_SCRATCH        EQU SYSVAR_BASE + $8D   ; 4B — TMP (2B) + ERR_SP (2B)
; Tamaño total del bloque de sysvars: $91 bytes
	; --- Constantes de pantalla ---------------------------------------------
	SCR_COLS            EQU 33      ; Columnas + 1 (32 columnas visibles)
	SCR_ROWS            EQU 24      ; Filas (24 filas visibles)
	SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS
	    pop namespace
#line 28 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
#line 32 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
	    push namespace core
__ARRAY_PTR:   ;; computes an array offset from a pointer
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c    ;; HL <-- [HL]
__ARRAY:
	    PROC
	    LOCAL LOOP
	    LOCAL ARRAY_END
	    LOCAL TMP_ARR_PTR            ; Ptr to Array DATA region. Stored temporarily
	    LOCAL LBOUND_PTR, UBOUND_PTR ; LBound and UBound PTR indexes
	    LOCAL RET_ADDR               ; Contains the return address popped from the stack
LBOUND_PTR EQU ARRAY_SCRATCH   ; zx81sd: dedicated scratch, not MEMBOT
	UBOUND_PTR EQU LBOUND_PTR + 2  ; Next 2 bytes for UBOUND PTR
	RET_ADDR EQU UBOUND_PTR + 2    ; Next 2 bytes for RET_ADDR
	TMP_ARR_PTR EQU RET_ADDR + 2   ; Next 2 bytes for TMP_ARR_PTR
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl      ; DE <-- PTR to Dim sizes table
	    ld (TMP_ARR_PTR), hl  ; HL = Array __DATA__.__PTR__
	    inc hl
	    inc hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)  ; BC <-- Array __LBOUND__ PTR
	    ld (LBOUND_PTR), bc  ; Store it for later
#line 74 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
	    ex de, hl   ; HL <-- PTR to Dim sizes table, DE <-- dummy
	    ex (sp), hl	; Return address in HL, PTR Dim sizes table onto Stack
	    ld (RET_ADDR), hl ; Stores it for later
	    exx
	    pop hl		; Will use H'L' as the pointer to Dim sizes table
	    ld c, (hl)	; Loads Number of dimensions from (hl)
	    inc hl
	    ld b, (hl)
	    inc hl		; Ready
	    exx
	    ld hl, 0	; HL = Element Offset "accumulator"
LOOP:
	    ex de, hl   ; DE = Element Offset
	    ld hl, (LBOUND_PTR)
	    ld a, h
	    or l
	    ld b, h
	    ld c, l
	    jr z, 1f
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    ld (LBOUND_PTR), hl
1:
	    pop hl      ; Get next index (Ai) from the stack
	    sbc hl, bc  ; Subtract LBOUND
#line 124 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
	    add hl, de	; Adds current index
	    exx			; Checks if B'C' = 0
	    ld a, b		; Which means we must exit (last element is not multiplied by anything)
	    or c
	    jr z, ARRAY_END		; if B'Ci == 0 we are done
	    dec bc				; Decrements loop counter
	    ld e, (hl)			; Loads next dimension size into D'E'
	    inc hl
	    ld d, (hl)
	    inc hl
	    push de
	    exx
	    pop de				; DE = Max bound Number (i-th dimension)
	    call __FMUL16        ; HL <= HL * DE mod 65536
	    jp LOOP
ARRAY_END:
	    ld a, (hl)
	    exx
#line 154 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 164 "/zxbasic/src/lib/arch/zx81sd/runtime/array/array.asm"
	    ex de, hl
	    ld hl, (TMP_ARR_PTR)
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    add hl, de  ; Adds element start
	    ld de, (RET_ADDR)
	    push de
	    ret
	    ENDP
	    pop namespace
#line 458 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/array/arrayalloc.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/mem/calloc.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the MIT license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the MIT license on the internet
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/mem/alloc.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the MIT license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the MIT license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be freed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/mem/heapinit.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	;  __MEM_INIT must be called to initalize this library with the
	; standard parameters
	; ---------------------------------------------------------------------
	    push namespace core
__MEM_INIT: ; Initializes the library using (RAMTOP) as start, and
	    ld hl, ZXBASIC_MEM_HEAP  ; Change this with other address of heap start
	    ld de, ZXBASIC_HEAP_SIZE ; Change this with your size
	; ---------------------------------------------------------------------
	;  __MEM_INIT2 initalizes this library
; Parameters:
;   HL : Memory address of 1st byte of the memory heap
;   DE : Length in bytes of the Memory Heap
	; ---------------------------------------------------------------------
__MEM_INIT2:
	    ; HL as TOP
	    PROC
	    dec de
	    dec de
	    dec de
	    dec de        ; DE = length - 4; HL = start
	    ; This is done, because we require 4 bytes for the empty dummy-header block
	    xor a
	    ld (hl), a
	    inc hl
    ld (hl), a ; First "free" block is a header: size=0, Pointer=&(Block) + 4
	    inc hl
	    ld b, h
	    ld c, l
	    inc bc
	    inc bc      ; BC = starts of next block
	    ld (hl), c
	    inc hl
	    ld (hl), b
	    inc hl      ; Pointer to next block
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl      ; Block size (should be length - 4 at start); This block contains all the available memory
	    ld (hl), a ; NULL (0000h) ; No more blocks (a list with a single block)
	    inc hl
	    ld (hl), a
	    ld a, 201
	    ld (__MEM_INIT), a; "Pokes" with a RET so ensure this routine is not called again
	    ret
	    ENDP
	    pop namespace
#line 70 "/zxbasic/src/lib/arch/zx48k/runtime/mem/alloc.asm"
	; ---------------------------------------------------------------------
	; MEM_ALLOC
	;  Allocates a block of memory in the heap.
	;
	; Parameters
	;  BC = Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	; ---------------------------------------------------------------------
	    push namespace core
MEM_ALLOC:
__MEM_ALLOC: ; Returns the 1st free block found of the given length (in BC)
	    PROC
	    LOCAL __MEM_LOOP
	    LOCAL __MEM_DONE
	    LOCAL __MEM_SUBTRACT
	    LOCAL __MEM_START
	    LOCAL TEMP, TEMP0
	TEMP EQU TEMP0 + 1
	    ld hl, 0
	    ld (TEMP), hl
__MEM_START:
	    ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
	    inc bc
	    inc bc  ; BC = BC + 2 ; block size needs 2 extra bytes for hidden pointer
__MEM_LOOP:  ; Loads lengh at (HL, HL+). If Lenght >= BC, jump to __MEM_DONE
	    ld a, h ;  HL = NULL (No memory available?)
	    or l
#line 113 "/zxbasic/src/lib/arch/zx48k/runtime/mem/alloc.asm"
	    ret z ; NULL
#line 115 "/zxbasic/src/lib/arch/zx48k/runtime/mem/alloc.asm"
	    ; HL = Pointer to Free block
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl          ; DE = Block Length
	    push hl         ; HL = *pointer to -> next block
	    ex de, hl
	    or a            ; CF = 0
	    sbc hl, bc      ; FREE >= BC (Length)  (HL = BlockLength - Length)
	    jp nc, __MEM_DONE
	    pop hl
	    ld (TEMP), hl
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    ex de, hl
	    jp __MEM_LOOP
__MEM_DONE:  ; A free block has been found.
	    ; Check if at least 4 bytes remains free (HL >= 4)
	    push hl
	    exx  ; exx to preserve bc
	    pop hl
	    ld bc, 4
	    or a
	    sbc hl, bc
	    exx
	    jp nc, __MEM_SUBTRACT
	    ; At this point...
	    ; less than 4 bytes remains free. So we return this block entirely
	    ; We must link the previous block with the next to this one
	    ; (DE) => Pointer to next block
	    ; (TEMP) => &(previous->next)
	    pop hl     ; Discard current block pointer
	    push de
	    ex de, hl  ; DE = Previous block pointer; (HL) = Next block pointer
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a    ; HL = (HL)
	    ex de, hl  ; HL = Previous block pointer; DE = Next block pointer
TEMP0:
	    ld hl, 0   ; Pre-previous block pointer
	    ld (hl), e
	    inc hl
	    ld (hl), d ; LINKED
	    pop hl ; Returning block.
	    ret
__MEM_SUBTRACT:
	    ; At this point we have to store HL value (Length - BC) into (DE - 2)
	    ex de, hl
	    dec hl
	    ld (hl), d
	    dec hl
	    ld (hl), e ; Store new block length
	    add hl, de ; New length + DE => free-block start
	    pop de     ; Remove previous HL off the stack
	    ld (hl), c ; Store length on its 1st word
	    inc hl
	    ld (hl), b
	    inc hl     ; Return hl
	    ret
	    ENDP
	    pop namespace
#line 13 "/zxbasic/src/lib/arch/zx48k/runtime/mem/calloc.asm"
	; ---------------------------------------------------------------------
	; MEM_CALLOC
	;  Allocates a block of memory in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  BC = Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	; ---------------------------------------------------------------------
	    push namespace core
__MEM_CALLOC:
	    push bc
	    call __MEM_ALLOC
	    pop bc
	    ld a, h
	    or l
	    ret z  ; No memory
	    ld (hl), 0
	    dec bc
	    ld a, b
	    or c
	    ret z  ; Already filled (1 byte-length block)
	    ld d, h
	    ld e, l
	    inc de
	    push hl
	    ldir
	    pop hl
	    ret
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/array/arrayalloc.asm"
	; ---------------------------------------------------------------------
	; __ALLOC_LOCAL_ARRAY
	;  Allocates an array element area in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;
; Returns:
	;  HL = (IX + HL) + 4
	; ---------------------------------------------------------------------
	    push namespace core
__ALLOC_LOCAL_ARRAY:
	    push de
	    push ix
	    pop de
	    add hl, de  ; hl = ix + hl
	    pop de
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl
	    push hl
	    call __MEM_CALLOC
	    pop de
	    ex de, hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    ret
	; ---------------------------------------------------------------------
	; __ALLOC_INITIALIZED_LOCAL_ARRAY
	;  Allocates an array element area in the heap, and clears it filling it
	;  with data whose pointer (PTR) is in the stack
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;  [SP + 2] = PTR to the element area
	;
; Returns:
	;  HL = (IX + HL) + 4
	; ---------------------------------------------------------------------
__ALLOC_INITIALIZED_LOCAL_ARRAY:
	    push bc
	    call __ALLOC_LOCAL_ARRAY
	    pop bc
	    ;; Swaps [SP], [SP + 2]
	    exx
	    pop hl       ; HL <- RET address
	    ex (sp), hl  ; HL <- Data table, [SP] <- RET address
	    push hl      ; [SP] <- Data table
	    exx
	    ex (sp), hl  ; HL = Data table, (SP) = (IX + HL + 4) - start of array address lbound
	    ; HL = data table
	    ; BC = length
	    ; DE = new data area
	    ldir
	    pop hl  ; HL = addr of LBound area if used
	    ret
#line 142 "/zxbasic/src/lib/arch/zx48k/runtime/array/arrayalloc.asm"
	    pop namespace
#line 459 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/asc.asm"
	; Returns the ascii code for the given str
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/mem/free.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	; MEM_FREE
	;  Frees a block of memory
	;
; Parameters:
	;  HL = Pointer to the block to be freed. If HL is NULL (0) nothing
	;  is done
	; ---------------------------------------------------------------------
	    push namespace core
MEM_FREE:
__MEM_FREE: ; Frees the block pointed by HL
	    ; HL DE BC & AF modified
	    PROC
	    LOCAL __MEM_LOOP2
	    LOCAL __MEM_LINK_PREV
	    LOCAL __MEM_JOIN_TEST
	    LOCAL __MEM_BLOCK_JOIN
	    ld a, h
	    or l
	    ret z       ; Return if NULL pointer
	    dec hl
	    dec hl
	    ld b, h
	    ld c, l    ; BC = Block pointer
	    ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
__MEM_LOOP2:
	    inc hl
	    inc hl     ; Next block ptr
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; Block next ptr
	    ex de, hl  ; DE = &(block->next); HL = block->next
	    ld a, h    ; HL == NULL?
	    or l
	    jp z, __MEM_LINK_PREV; if so, link with previous
	    or a       ; Clear carry flag
	    sbc hl, bc ; Carry if BC > HL => This block if before
	    add hl, bc ; Restores HL, preserving Carry flag
	    jp c, __MEM_LOOP2 ; This block is before. Keep searching PASS the block
	;------ At this point current HL is PAST BC, so we must link (DE) with BC, and HL in BC->next
__MEM_LINK_PREV:    ; Link (DE) with BC, and BC->next with HL
	    ex de, hl
	    push hl
	    dec hl
	    ld (hl), c
	    inc hl
	    ld (hl), b ; (DE) <- BC
	    ld h, b    ; HL <- BC (Free block ptr)
	    ld l, c
	    inc hl     ; Skip block length (2 bytes)
	    inc hl
	    ld (hl), e ; Block->next = DE
	    inc hl
	    ld (hl), d
	    ; --- LINKED ; HL = &(BC->next) + 2
	    call __MEM_JOIN_TEST
	    pop hl
__MEM_JOIN_TEST:   ; Checks for fragmented contiguous blocks and joins them
	    ; hl = Ptr to current block + 2
	    ld d, (hl)
	    dec hl
	    ld e, (hl)
	    dec hl
	    ld b, (hl) ; Loads block length into BC
	    dec hl
	    ld c, (hl) ;
	    push hl    ; Saves it for later
	    add hl, bc ; Adds its length. If HL == DE now, it must be joined
	    or a
	    sbc hl, de ; If Z, then HL == DE => We must join
	    pop hl
	    ret nz
__MEM_BLOCK_JOIN:  ; Joins current block (pointed by HL) with next one (pointed by DE). HL->length already in BC
	    push hl    ; Saves it for later
	    ex de, hl
	    ld e, (hl) ; DE -> block->next->length
	    inc hl
	    ld d, (hl)
	    inc hl
	    ex de, hl  ; DE = &(block->next)
	    add hl, bc ; HL = Total Length
	    ld b, h
	    ld c, l    ; BC = Total Length
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl) ; DE = block->next
	    pop hl     ; Recovers Pointer to block
	    ld (hl), c
	    inc hl
	    ld (hl), b ; Length Saved
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d ; Next saved
	    ret
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/asc.asm"
	    push namespace core
__ASC:
	    PROC
	    LOCAL __ASC_END
	    ex af, af'	; Saves free_mem flag
	    ld a, h
	    or l
	    ret z		; NULL? return
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    ld a, b
	    or c
	    jr z, __ASC_END		; No length? return
	    inc hl
	    ld a, (hl)
	    dec hl
__ASC_END:
	    dec hl
	    ex af, af'
	    or a
	    call nz, __MEM_FREE	; Free memory if needed
	    ex af, af'	; Recover result
	    ret
	    ENDP
	    pop namespace
#line 460 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bitwise/bor16.asm"
; vim:ts=4:et:
	; FASTCALL bitwise or 16 version.
	; result in HL
; __FASTCALL__ version (operands: A, H)
	; Performs 16bit or 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL OR DE
	    push namespace core
__BOR16:
	    ld a, h
	    or d
	    ld h, a
	    ld a, l
	    or e
	    ld l, a
	    ret
	    pop namespace
#line 461 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lei16.asm"
	    push namespace core
__LEI16:
	    PROC
	    LOCAL checkParity
	    or a
	    sbc hl, de
	    ld a, 1
	    ret z
	    jp po, checkParity
	    ld a, h
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 462 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti16.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lei8.asm"
	    push namespace core
__LEI8: ; Signed <= comparison for 8bit int
	    ; A <= H (registers)
	    PROC
	    LOCAL checkParity
	    sub h
	    jr nz, __LTI
	    inc a
	    ret
__LTI8:  ; Test 8 bit values A < H
	    sub h
__LTI:   ; Generic signed comparison
	    jp po, checkParity
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/cmp/lti16.asm"
	    push namespace core
__LTI16: ; Test 8 bit values HL < DE
    ; Returns result in A: 0 = False, !0 = True
	    PROC
	    LOCAL checkParity
	    or a
	    sbc hl, de
	    jp po, checkParity
	    ld a, h
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 463 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/copy_attr.asm"
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
; vim:ts=4:sw=4:et:
	; PRINT command routine
	; Does not print attribute. Use PRINT_STR or PRINT_NUM for that
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/sposn.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/attr.asm"
	; Attribute routines
; vim:ts=4:et:sw:
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/in_screen.asm"
	    push namespace core
__IN_SCREEN:
	    ; Returns NO carry if current coords (D, E)
	    ; are OUT of the screen limits
	    PROC
	    LOCAL __IN_SCREEN_ERR
	    ld hl, SCR_SIZE
	    ld a, e
	    cp l
	    jr nc, __IN_SCREEN_ERR	; Do nothing and return if out of range
	    ld a, d
	    cp h
	    ret c                       ; Return if carry (OK)
__IN_SCREEN_ERR:
__OUT_OF_SCREEN_ERR:
	    ; Jumps here if out of screen
	    ld a, ERROR_OutOfScreen
	    jp __STOP   ; Saves error code and exits
	    ENDP
	    pop namespace
#line 7 "/zxbasic/src/lib/arch/zx48k/runtime/attr.asm"
	    push namespace core
__ATTR_ADDR:
	    ; calc start address in DE (as (32 * d) + e)
    ; Contributed by Santiago Romero at http://www.speccy.org
	    ld h, 0                     ;  7 T-States
	    ld a, d                     ;  4 T-States
	    ld d, h
	    add a, a     ; a * 2        ;  4 T-States
	    add a, a     ; a * 4        ;  4 T-States
	    ld l, a      ; HL = A * 4   ;  4 T-States
	    add hl, hl   ; HL = A * 8   ; 15 T-States
	    add hl, hl   ; HL = A * 16  ; 15 T-States
	    add hl, hl   ; HL = A * 32  ; 15 T-States
	    add hl, de
	    ld de, (SCREEN_ATTR_ADDR)    ; Adds the screen address
	    add hl, de
	    ; Return current screen address in HL
	    ret
	; Sets the attribute at a given screen coordinate (D, E).
	; The attribute is taken from the ATTR_T memory variable
	; Used by PRINT routines
SET_ATTR:
	    ; Checks for valid coords
	    call __IN_SCREEN
	    ret nc
	    call __ATTR_ADDR
__SET_ATTR:
	    ; Internal __FASTCALL__ Entry used by printing routines
	    ; HL contains the address of the ATTR cell to set
	    PROC
__SET_ATTR2:  ; Sets attr from ATTR_T to (HL) which points to the scr address
	    ld de, (ATTR_T)    ; E = ATTR_T, D = MASK_T
	    ld a, d
	    and (hl)
	    ld c, a    ; C = current screen color, masked
	    ld a, d
	    cpl        ; Negate mask
	    and e    ; Mask current attributes
	    or c    ; Mix them
	    ld (hl), a ; Store result in screen
	    ret
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/sposn.asm"
	; Printing positioning library.
	    push namespace core
	; Loads into DE current ROW, COL print position from S_POSN mem var.
__LOAD_S_POSN:
	    PROC
	    ld de, (S_POSN)
	    ld hl, SCR_SIZE
	    or a
	    sbc hl, de
	    ex de, hl
	    ret
	    ENDP
	; Saves ROW, COL from DE into S_POSN mem var.
__SAVE_S_POSN:
	    PROC
	    ld hl, SCR_SIZE
	    or a
	    sbc hl, de
	    ld (S_POSN), hl ; saves it again
__SET_SCR_PTR:  ;; Fast
	    push de
	    call __ATTR_ADDR
	    ld (DFCCL), hl
	    pop de
	    ld a, d
	    ld c, a     ; Saves it for later
	    and 0F8h    ; Masks 3 lower bit ; zy
	    ld d, a
	    ld a, c     ; Recovers it
	    and 07h     ; MOD 7 ; y1
	    rrca
	    rrca
	    rrca
	    or e
	    ld e, a
	    ld hl, (SCREEN_ADDR)
	    add hl, de    ; HL = Screen address + DE
	    ld (DFCC), hl
	    ret
	    ENDP
	    pop namespace
#line 6 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/table_jump.asm"
	    push namespace core
JUMP_HL_PLUS_2A: ; Does JP (HL + A*2) Modifies DE. Modifies A
	    add a, a
JUMP_HL_PLUS_A:	 ; Does JP (HL + A) Modifies DE
	    ld e, a
	    ld d, 0
JUMP_HL_PLUS_DE: ; Does JP (HL + DE)
	    add hl, de
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    ex de, hl
CALL_HL:
	    jp (hl)
	    pop namespace
#line 8 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/ink.asm"
	; Sets ink color in ATTR_P permanently
; Parameter: Paper color in A register
	    push namespace core
INK:
	    PROC
	    LOCAL __SET_INK
	    LOCAL __SET_INK2
	    ld de, ATTR_P
__SET_INK:
	    cp 8
	    jr nz, __SET_INK2
	    inc de ; Points DE to MASK_T or MASK_P
	    ld a, (de)
	    or 7 ; Set bits 0,1,2 to enable transparency
	    ld (de), a
	    ret
__SET_INK2:
	    ; Another entry. This will set the ink color at location pointer by DE
	    and 7	; # Gets color mod 8
	    ld b, a	; Saves the color
	    ld a, (de)
	    and 0F8h ; Clears previous value
	    or b
	    ld (de), a
	    inc de ; Points DE to MASK_T or MASK_P
	    ld a, (de)
	    and 0F8h ; Reset bits 0,1,2 sign to disable transparency
	    ld (de), a ; Store new attr
	    ret
	; Sets the INK color passed in A register in the ATTR_T variable
INK_TMP:
	    ld de, ATTR_T
	    jp __SET_INK
	    ENDP
	    pop namespace
#line 9 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/paper.asm"
	; Sets paper color in ATTR_P permanently
; Parameter: Paper color in A register
	    push namespace core
PAPER:
	    PROC
	    LOCAL __SET_PAPER
	    LOCAL __SET_PAPER2
	    ld de, ATTR_P
__SET_PAPER:
	    cp 8
	    jr nz, __SET_PAPER2
	    inc de
	    ld a, (de)
	    or 038h
	    ld (de), a
	    ret
	    ; Another entry. This will set the paper color at location pointer by DE
__SET_PAPER2:
	    and 7	; # Remove
	    rlca
	    rlca
	    rlca		; a *= 8
	    ld b, a	; Saves the color
	    ld a, (de)
	    and 0C7h ; Clears previous value
	    or b
	    ld (de), a
	    inc de ; Points to MASK_T or MASK_P accordingly
	    ld a, (de)
	    and 0C7h  ; Resets bits 3,4,5
	    ld (de), a
	    ret
	; Sets the PAPER color passed in A register in the ATTR_T variable
PAPER_TMP:
	    ld de, ATTR_T
	    jp __SET_PAPER
	    ENDP
	    pop namespace
#line 10 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/flash.asm"
	; Sets flash flag in ATTR_P permanently
; Parameter: Paper color in A register
	    push namespace core
FLASH:
	    ld hl, ATTR_P
	    PROC
	    LOCAL IS_TR
	    LOCAL IS_ZERO
__SET_FLASH:
	    ; Another entry. This will set the flash flag at location pointer by DE
	    cp 8
	    jr z, IS_TR
	    ; # Convert to 0/1
	    or a
	    jr z, IS_ZERO
	    ld a, 0x80
IS_ZERO:
	    ld b, a	; Saves the color
	    ld a, (hl)
	    and 07Fh ; Clears previous value
	    or b
	    ld (hl), a
	    inc hl
	    res 7, (hl)  ;Reset bit 7 to disable transparency
	    ret
IS_TR:  ; transparent
	    inc hl ; Points DE to MASK_T or MASK_P
	    set 7, (hl)  ;Set bit 7 to enable transparency
	    ret
	; Sets the FLASH flag passed in A register in the ATTR_T variable
FLASH_TMP:
	    ld hl, ATTR_T
	    jr __SET_FLASH
	    ENDP
	    pop namespace
#line 11 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bright.asm"
	; Sets bright flag in ATTR_P permanently
; Parameter: Paper color in A register
	    push namespace core
BRIGHT:
	    ld hl, ATTR_P
	    PROC
	    LOCAL IS_TR
	    LOCAL IS_ZERO
__SET_BRIGHT:
	    ; Another entry. This will set the bright flag at location pointer by DE
	    cp 8
	    jr z, IS_TR
	    ; # Convert to 0/1
	    or a
	    jr z, IS_ZERO
	    ld a, 0x40
IS_ZERO:
	    ld b, a	; Saves the color
	    ld a, (hl)
	    and 0BFh ; Clears previous value
	    or b
	    ld (hl), a
	    inc hl
	    res 6, (hl)  ;Reset bit 6 to disable transparency
	    ret
IS_TR:  ; transparent
	    inc hl ; Points DE to MASK_T or MASK_P
	    set 6, (hl)  ;Set bit 6 to enable transparency
	    ret
	; Sets the BRIGHT flag passed in A register in the ATTR_T variable
BRIGHT_TMP:
	    ld hl, ATTR_T
	    jr __SET_BRIGHT
	    ENDP
	    pop namespace
#line 12 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/over.asm"
	; Sets OVER flag in P_FLAG permanently
; Parameter: OVER flag in bit 0 of A register
	    push namespace core
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
	    pop namespace
#line 13 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/inverse.asm"
	; Sets INVERSE flag in P_FLAG permanently
; Parameter: INVERSE flag in bit 0 of A register
	    push namespace core
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
	    pop namespace
#line 14 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bold.asm"
	; Sets BOLD flag in P_FLAG permanently
; Parameter: BOLD flag in bit 0 of A register
	    push namespace core
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
	    pop namespace
#line 15 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/italic.asm"
	; Sets ITALIC flag in P_FLAG permanently
; Parameter: ITALIC flag in bit 0 of A register
	    push namespace core
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
	    pop namespace
#line 16 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	; Putting a comment starting with @INIT <address>
	; will make the compiler to add a CALL to <address>
	; It is useful for initialization routines.
	    push namespace core
__PRINT_INIT: ; To be called before program starts (initializes library)
	    PROC
	    ld hl, __PRINT_START
	    ld (PRINT_JUMP_STATE), hl
	    ;; Clears ATTR2 flags (OVER 2, etc)
	    xor a
	    ld (FLAGS2), a
	    ld hl, TV_FLAG
	    res 0, (hl)
	    LOCAL SET_SCR_ADDR
	    call __LOAD_S_POSN
	    jp __SET_SCR_PTR
	    ;; Receives HL = future value of S_POSN
	    ;; Stores it at (S_POSN) and refresh screen pointers (ATTR, SCR)
SET_SCR_ADDR:
	    ld (S_POSN), hl
	    ex de, hl
	    ld hl, SCR_SIZE
	    or a
	    sbc hl, de
	    ex de, hl
	    dec e
	    jp __SET_SCR_PTR
__PRINTCHAR: ; Print character store in accumulator (A register)
	    ; Modifies H'L', B'C', A'F', D'E', A
	    LOCAL PO_GR_1
	    LOCAL __PRCHAR
	    LOCAL __PRINT_JUMP
	    LOCAL __SRCADDR
	    LOCAL __PRINT_UDG
	    LOCAL __PRGRAPH
	    LOCAL __PRINT_START
	PRINT_JUMP_STATE EQU __PRINT_JUMP + 2
__PRINT_JUMP:
	    exx                 ; Switch to alternative registers
	    jp __PRINT_START    ; Where to jump. If we print 22 (AT), next two calls jumps to AT1 and AT2 respectively
__PRINT_START:
__PRINT_CHR:
	    cp ' '
	    jp c, __PRINT_SPECIAL    ; Characters below ' ' are special ones (> 127 bytes away)
	    ex af, af'               ; Saves a value (char to print) for later
	    ld hl, (S_POSN)
	    dec l
	    jr nz, 1f
	    ld l, SCR_COLS - 1
	    dec h
	    jr nz, 2f
	    inc h
	    push hl
	    call __SCROLL_SCR
	    pop hl
#line 94 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
2:
	    call SET_SCR_ADDR
	    jr 4f
1:
	    ld (S_POSN), hl
4:
	    ex af, af'
	    cp 80h    ; Is it a "normal" (printable) char
	    jr c, __SRCADDR
	    cp 90h    ; Is it an UDG?
	    jr nc, __PRINT_UDG
	    ; Print an 8 bit pattern (80h to 8Fh)
	    ld b, a
	    call PO_GR_1 ; This ROM routine will generate the bit pattern at MEM0
	    ld hl, MEM0
	    jp __PRGRAPH
	; PO_GR_1 se incluye como rutina propia (po_gr_1.asm), no desde ROM Spectrum
#line 1 "/zxbasic/src/lib/arch/zx81sd/runtime/po_gr_1.asm"
	; PO_GR_1 — Genera el patrón de bits para caracteres gráficos 128-143
	; Sustituye a PO-GR-1 ($0B38, ROM Spectrum). Mismo algoritmo que la ROM.
	;
	; Los caracteres gráficos Spectrum (CHR$ 128 a CHR$ 143) son bloques
	; de 2×2 cuadrantes. El nibble bajo del código determina qué cuadrantes
; están encendidos, con el mapeo EXACTO de la ROM (PO-GR-2, $0B3E):
	;
	;   bit 0 = cuadrante superior DERECHO   → $0F en filas 0-3
	;   bit 1 = cuadrante superior IZQUIERDO → $F0 en filas 0-3
	;   bit 2 = cuadrante inferior DERECHO   → $0F en filas 4-7
	;   bit 3 = cuadrante inferior IZQUIERDO → $F0 en filas 4-7
	;
	; (CHR$(129) = ▝, CHR$(130) = ▘, CHR$(143) = bloque macizo.)
	;
; Entrada: B = código de carácter (128-143), solo se usan bits 3-0
; Salida:  MEM0 (8 bytes) = patrón del carácter; HL = MEM0
; Destruye: A, B, C
	    push namespace core
PO_GR_1:
	    PROC
	    LOCAL PO_GR_HALF, PO_GR_FILL
	    ld   a, b
	    and  $0F
	    ld   b, a               ; B = bits de cuadrante
	    ld   hl, MEM0
	    call PO_GR_HALF         ; filas 0-3 (bits 0-1)
	    call PO_GR_HALF         ; filas 4-7 (bits 2-3)
	    ld   hl, MEM0           ; devuelve el puntero al patrón
	    ret
	; Construye media celda (4 filas iguales) a partir de los dos bits
	; bajos de B, desplazándolos fuera. Igual que PO-GR-2 de la ROM.
PO_GR_HALF:
	    rr   b                  ; bit par → carry
	    sbc  a, a               ; $00 o $FF
	    and  $0F                ; mitad derecha
	    ld   c, a
	    rr   b                  ; bit impar → carry
	    sbc  a, a
	    and  $F0                ; mitad izquierda
	    or   c                  ; byte de la fila completo
	    ld   c, 4
PO_GR_FILL:
	    ld   (hl), a
	    inc  hl
	    dec  c
	    jr   nz, PO_GR_FILL
	    ret
	    ENDP
	    pop namespace
#line 117 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
__PRINT_UDG:
	    sub 90h ; Sub ASC code
	    ld bc, (UDG)
	    jr __PRGRAPH0
	__SOURCEADDR EQU (__SRCADDR + 1)    ; Address of the pointer to chars source
__SRCADDR:
	    ld bc, (CHARS)
__PRGRAPH0:
    add a, a   ; A = a * 2 (since a < 80h) ; Thanks to Metalbrain at http://foro.speccy.org
	    ld l, a
	    ld h, 0    ; HL = a * 2 (accumulator)
	    add hl, hl
	    add hl, hl ; HL = a * 8
	    add hl, bc ; HL = CHARS address
__PRGRAPH:
	    ex de, hl  ; HL = Write Address, DE = CHARS address
	    ld   a, (FLAGS2)
	    bit  2, a
	    call nz, __BOLD
#line 143 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    ld   a, (FLAGS2)
	    bit  4, a
	    call nz, __ITALIC
#line 149 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    ld hl, (DFCC)
	    push hl
	    ld b, 8 ; 8 bytes per char
__PRCHAR:
	    ld a, (de) ; DE *must* be source, and HL destiny
PRINT_MODE:     ; Which operation is used to write on the screen
    ; Set it with:
	    ; LD A, <OPERATION>
	    ; LD (PRINT_MODE), A
	    ;
    ; Available operations:
    ; NORMAL : 0h  --> NOP         ; OVER 0
    ; XOR    : AEh --> XOR (HL)    ; OVER 1
    ; OR     : B6h --> OR (HL)     ; PUTSPRITE
    ; AND    : A6h --> AND (HL)    ; PUTMASK
	    nop         ; Set to one of the values above
INVERSE_MODE:   ; 00 -> NOP -> INVERSE 0
	    nop         ; 2F -> CPL -> INVERSE 1
	    ld (hl), a
	    inc de
	    inc h     ; Next line
	    djnz __PRCHAR
	    pop hl
	    inc hl
	    ld (DFCC), hl
	    ld hl, (DFCCL)   ; current ATTR Pos
	    inc hl
	    ld (DFCCL), hl
	    dec hl
	    call __SET_ATTR
	    exx
	    ret
	; ------------- SPECIAL CHARS (< 32) -----------------
__PRINT_SPECIAL:    ; Jumps here if it is a special char
	    ld hl, __PRINT_TABLE
	    jp JUMP_HL_PLUS_2A
PRINT_EOL:        ; Called WHENEVER there is no ";" at end of PRINT sentence
	    exx
__PRINT_0Dh:        ; Called WHEN printing CHR$(13)
	    ld hl, (S_POSN)
	    dec l
	    jr nz, 1f
	    dec h
	    jr nz, 1f
	    inc h
	    push hl
	    call __SCROLL_SCR
	    pop hl
#line 214 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
1:
	    ld l, 1
__PRINT_EOL_END:
	    call SET_SCR_ADDR
	    exx
	    ret
__PRINT_COM:
	    exx
	    push hl
	    push de
	    push bc
	    call PRINT_COMMA
	    pop bc
	    pop de
	    pop hl
	    ret
__PRINT_TAB:
	    ld hl, __PRINT_TAB1
	    jr __PRINT_SET_STATE
__PRINT_TAB1:
	    ld (MEM0), a
	    ld hl, __PRINT_TAB2
	    jr __PRINT_SET_STATE
__PRINT_TAB2:
	    ld a, (MEM0)        ; Load tab code (ignore the current one)
	    ld hl, __PRINT_START
	    ld (PRINT_JUMP_STATE), hl
	    exx
	    push hl
	    push bc
	    push de
	    call PRINT_TAB
	    pop de
	    pop bc
	    pop hl
	    ret
__PRINT_AT:
	    ld hl, __PRINT_AT1
	    jr __PRINT_SET_STATE
__PRINT_NOP:
__PRINT_RESTART:
	    ld hl, __PRINT_START
__PRINT_SET_STATE:
	    ld (PRINT_JUMP_STATE), hl    ; Saves next entry call
	    exx
	    ret
__PRINT_AT1:    ; Jumps here if waiting for 1st parameter
	    ld hl, (S_POSN)
	    ld h, a
	    ld a, SCR_ROWS
	    sub h
	    ld (S_POSN + 1), a
	    ld hl, __PRINT_AT2
	    jr __PRINT_SET_STATE
__PRINT_AT2:
	    call __LOAD_S_POSN
	    ld e, a
	    call __SAVE_S_POSN
	    jp __PRINT_RESTART
__PRINT_DEL:
	    call __LOAD_S_POSN        ; Gets current screen position
	    dec e
	    ld a, -1
	    cp e
	    jr nz, 3f
	    ld e, SCR_COLS - 2
	    dec d
	    cp d
	    jr nz, 3f
	    ld d, SCR_ROWS - 1
3:
	    call __SAVE_S_POSN
	    exx
	    ret
__PRINT_INK:
	    ld hl, __PRINT_INK2
	    jr __PRINT_SET_STATE
__PRINT_INK2:
	    call INK_TMP
	    jp __PRINT_RESTART
__PRINT_PAP:
	    ld hl, __PRINT_PAP2
	    jr __PRINT_SET_STATE
__PRINT_PAP2:
	    call PAPER_TMP
	    jp __PRINT_RESTART
__PRINT_FLA:
	    ld hl, __PRINT_FLA2
	    jr __PRINT_SET_STATE
__PRINT_FLA2:
	    call FLASH_TMP
	    jp __PRINT_RESTART
__PRINT_BRI:
	    ld hl, __PRINT_BRI2
	    jr __PRINT_SET_STATE
__PRINT_BRI2:
	    call BRIGHT_TMP
	    jp __PRINT_RESTART
__PRINT_INV:
	    ld hl, __PRINT_INV2
	    jr __PRINT_SET_STATE
__PRINT_INV2:
	    call INVERSE_TMP
	    jp __PRINT_RESTART
__PRINT_OVR:
	    ld hl, __PRINT_OVR2
	    jr __PRINT_SET_STATE
__PRINT_OVR2:
	    call OVER_TMP
	    jp __PRINT_RESTART
__PRINT_BOLD:
	    ld hl, __PRINT_BOLD2
	    jp __PRINT_SET_STATE
__PRINT_BOLD2:
	    call BOLD_TMP
	    jp __PRINT_RESTART
#line 358 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
__PRINT_ITA:
	    ld hl, __PRINT_ITA2
	    jp __PRINT_SET_STATE
__PRINT_ITA2:
	    call ITALIC_TMP
	    jp __PRINT_RESTART
#line 368 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    LOCAL __BOLD
__BOLD:
	    push hl
	    ld hl, MEM0
	    ld b, 8
1:
	    ld a, (de)
	    ld c, a
	    rlca
	    or c
	    ld (hl), a
	    inc hl
	    inc de
	    djnz 1b
	    pop hl
	    ld de, MEM0
	    ret
#line 389 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    LOCAL __ITALIC
__ITALIC:
	    push hl
	    ld hl, MEM0
	    ex de, hl
	    ld bc, 8
	    ldir
	    ld hl, MEM0
	    srl (hl)
	    inc hl
	    srl (hl)
	    inc hl
	    srl (hl)
	    inc hl
	    inc hl
	    inc hl
	    sla (hl)
	    inc hl
	    sla (hl)
	    inc hl
	    sla (hl)
	    pop hl
	    ld de, MEM0
	    ret
#line 417 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    LOCAL __SCROLL_SCR
; En zx81sd el scroll se hace SIEMPRE con la implementacion por buffer:
	; la variante del zx48k ("__SCROLL_SCR EQU 0DFEh") delega en la rutina
	; CL-SC-ALL de la ROM del Spectrum, que aqui no esta mapeada — ese CALL
; ejecutaria codigo arbitrario del programa (bug cazado con flights.bas:
	; el primer PRINT que desbordaba la pantalla saltaba a la linea BASIC
	; que casualmente ocupara $0DFE).
__SCROLL_SCR:  ;; Scrolls screen and attrs 1 row up
	    ld de, (SCREEN_ADDR)
	    ld b, 3
3:
	    push bc
	    ld a, 8
1:
	    ld hl, 32
	    add hl, de
	    ld bc, 32 * 7
	    push de
	    ldir
	    pop de
	    inc d
	    dec a
	    jr nz, 1b
	    push hl
	    ld bc, -32 - 256 * 7
	    add hl, bc
	    ex de, hl
	    ld a, 8
2:
	    ld bc, 32
	    push hl
	    push de
	    ldir
	    pop de
	    pop hl
	    inc d
	    inc h
	    dec a
	    jr nz, 2b
	    pop de
	    pop bc
	    djnz 3b
	    dec de
	    ld h, d
	    ld l, e
	    ld a, 8
3:
	    push hl
	    push de
	    ld (hl), b
	    dec de
	    ld bc, 31
	    lddr
	    pop de
	    pop hl
	    dec d
	    dec h
	    dec a
	    jr nz, 3b
	    ld de, (SCREEN_ATTR_ADDR)
	    ld hl, 32
	    add hl, de
	    ld bc, 32 * 23
	    ldir
	    ld h, d
	    ld l, e
	    ld a, (ATTR_P)
	    ld (hl), a
	    inc de
	    ld bc, 31
	    ldir
	    ret
#line 496 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
PRINT_COMMA:
	    call __LOAD_S_POSN
	    ld a, e
	    and 16
	    add a, 16
PRINT_TAB:
	    ; Tabulates the number of spaces in A register
	    ; If the current cursor position is already A, does nothing
	    PROC
	    LOCAL LOOP
	    call __LOAD_S_POSN ; e = current row
	    sub e
	    and 31
	    ret z
	    ld b, a
LOOP:
	    ld a, ' '
	    call __PRINTCHAR
	    djnz LOOP
	    ret
	    ENDP
PRINT_AT: ; Changes cursor to ROW, COL
	    ; COL in A register
	    ; ROW in stack
	    pop hl    ; Ret address
	    ex (sp), hl ; callee H = ROW
	    ld l, a
	    ex de, hl
	    call __IN_SCREEN
	    ret nc    ; Return if out of screen
	    jp __SAVE_S_POSN
	    LOCAL __PRINT_COM
	    LOCAL __PRINT_AT1
	    LOCAL __PRINT_AT2
	    LOCAL __PRINT_BOLD
	    LOCAL __PRINT_ITA
	    LOCAL __PRINT_INK
	    LOCAL __PRINT_PAP
	    LOCAL __PRINT_SET_STATE
	    LOCAL __PRINT_TABLE
	    LOCAL __PRINT_TAB, __PRINT_TAB1, __PRINT_TAB2
	    LOCAL __PRINT_ITA2
#line 552 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
	    LOCAL __PRINT_BOLD2
#line 558 "/zxbasic/src/lib/arch/zx81sd/runtime/print.asm"
__PRINT_TABLE:    ; Jump table for 0 .. 22 codes
	    DW __PRINT_NOP    ;  0
	    DW __PRINT_NOP    ;  1
	    DW __PRINT_NOP    ;  2
	    DW __PRINT_NOP    ;  3
	    DW __PRINT_NOP    ;  4
	    DW __PRINT_NOP    ;  5
	    DW __PRINT_COM    ;  6 COMMA
	    DW __PRINT_NOP    ;  7
	    DW __PRINT_DEL    ;  8 DEL
	    DW __PRINT_NOP    ;  9
	    DW __PRINT_NOP    ; 10
	    DW __PRINT_NOP    ; 11
	    DW __PRINT_NOP    ; 12
	    DW __PRINT_0Dh    ; 13
	    DW __PRINT_BOLD   ; 14
	    DW __PRINT_ITA    ; 15
	    DW __PRINT_INK    ; 16
	    DW __PRINT_PAP    ; 17
	    DW __PRINT_FLA    ; 18
	    DW __PRINT_BRI    ; 19
	    DW __PRINT_INV    ; 20
	    DW __PRINT_OVR    ; 21
	    DW __PRINT_AT     ; 22 AT
	    DW __PRINT_TAB    ; 23 TAB
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/copy_attr.asm"
#line 4 "/zxbasic/src/lib/arch/zx48k/runtime/copy_attr.asm"
	    push namespace core
COPY_ATTR:
	    ; Just copies current permanent attribs into temporal attribs
	    ; and sets print mode
	    PROC
	    LOCAL INVERSE1
	    LOCAL __REFRESH_TMP
	INVERSE1 EQU 02Fh
	    ld hl, (ATTR_P)
	    ld (ATTR_T), hl
	    ld hl, FLAGS2
	    call __REFRESH_TMP
	    ld hl, P_FLAG
	    call __REFRESH_TMP
__SET_ATTR_MODE:		; Another entry to set print modes. A contains (P_FLAG)
	    LOCAL TABLE
	    LOCAL CONT2
	    rra					; Over bit to carry
	    ld a, (FLAGS2)
	    rla					; Over bit in bit 1, Over2 bit in bit 2
	    and 3				; Only bit 0 and 1 (OVER flag)
	    ld c, a
	    ld b, 0
	    ld hl, TABLE
	    add hl, bc
	    ld a, (hl)
	    ld (PRINT_MODE), a
	    ld hl, (P_FLAG)
	    xor a			; NOP -> INVERSE0
	    bit 2, l
	    jr z, CONT2
	    ld a, INVERSE1 	; CPL -> INVERSE1
CONT2:
	    ld (INVERSE_MODE), a
	    ret
TABLE:
	    nop				; NORMAL MODE
	    xor (hl)		; OVER 1 MODE
	    and (hl)		; OVER 2 MODE
	    or  (hl)		; OVER 3 MODE
#line 67 "/zxbasic/src/lib/arch/zx48k/runtime/copy_attr.asm"
__REFRESH_TMP:
	    ld a, (hl)
	    and 0b10101010
	    ld c, a
	    rra
	    or c
	    ld (hl), a
	    ret
	    ENDP
	    pop namespace
#line 464 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/loadstr.asm"
	; Loads a string (ptr) from HL
	; and duplicates it on dynamic memory again
	; Finally, it returns result pointer in HL
	    push namespace core
__ILOADSTR:		; This is the indirect pointer entry HL = (HL)
	    ld a, h
	    or l
	    ret z
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
__LOADSTR:		; __FASTCALL__ entry
	    ld a, h
	    or l
	    ret z	; Return if NULL
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    dec hl  ; BC = LEN(a$)
	    inc bc
	    inc bc	; BC = LEN(a$) + 2 (two bytes for length)
	    push hl
	    push bc
	    call __MEM_ALLOC
	    pop bc  ; Recover length
	    pop de  ; Recover origin
	    ld a, h
	    or l
	    ret z	; Return if NULL (No memory)
	    ex de, hl ; ldir takes HL as source, DE as destiny, so SWAP HL,DE
	    push de	; Saves destiny start
	    ldir	; Copies string (length number included)
	    pop hl	; Recovers destiny in hl as result
	    ret
	    pop namespace
#line 466 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/printu8.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/printi8.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/printnum.asm"
	    push namespace core
__PRINTU_START:
	    PROC
	    LOCAL __PRINTU_CONT
	    ld a, b
	    or a
	    jp nz, __PRINTU_CONT
	    ld a, '0'
	    jp __PRINT_DIGIT
__PRINTU_CONT:
	    pop af
	    push bc
	    call __PRINT_DIGIT
	    pop bc
	    djnz __PRINTU_CONT
	    ret
	    ENDP
__PRINT_MINUS: ; PRINT the MINUS (-) sign. CALLER must preserve registers
	    ld a, '-'
	    jp __PRINT_DIGIT
	__PRINT_DIGIT EQU __PRINTCHAR ; PRINTS the char in A register, and puts its attrs
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/printi8.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arith/div8.asm"
	    ; --------------------------------
	    push namespace core
__DIVU8:	; 8 bit unsigned integer division
	    ; Divides (Top of stack, High Byte) / A
	    pop hl	; --------------------------------
	    ex (sp), hl	; CALLEE
__DIVU8_FAST:	; Does A / H
	    ld l, h
	    ld h, a		; At this point do H / L
	    ld b, 8
	    xor a		; A = 0, Carry Flag = 0
__DIV8LOOP:
	    sla	h
	    rla
	    cp	l
	    jr	c, __DIV8NOSUB
	    sub	l
	    inc	h
__DIV8NOSUB:
	    djnz __DIV8LOOP
	    ld	l, a		; save remainder
	    ld	a, h		;
	    ret			; a = Quotient,
	    ; --------------------------------
__DIVI8:		; 8 bit signed integer division Divides (Top of stack) / A
	    pop hl		; --------------------------------
	    ex (sp), hl
__DIVI8_FAST:
	    ld e, a		; store operands for later
	    ld c, h
	    or a		; negative?
	    jp p, __DIV8A
	    neg			; Make it positive
__DIV8A:
	    ex af, af'
	    ld a, h
	    or a
	    jp p, __DIV8B
	    neg
	    ld h, a		; make it positive
__DIV8B:
	    ex af, af'
	    call __DIVU8_FAST
	    ld a, c
	    xor l		; bit 7 of A = 1 if result is negative
	    ld a, h		; Quotient
	    ret p		; return if positive
	    neg
	    ret
__MODU8:		; 8 bit module. REturns A mod (Top of stack) (unsigned operands)
	    pop hl
	    ex (sp), hl	; CALLEE
__MODU8_FAST:	; __FASTCALL__ entry
	    call __DIVU8_FAST
	    ld a, l		; Remainder
	    ret		; a = Modulus
__MODI8:		; 8 bit module. REturns A mod (Top of stack) (For singed operands)
	    pop hl
	    ex (sp), hl	; CALLEE
__MODI8_FAST:	; __FASTCALL__ entry
	    call __DIVI8_FAST
	    ld a, l		; remainder
	    ret		; a = Modulus
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/printi8.asm"
	    push namespace core
__PRINTI8:	; Prints an 8 bits number in Accumulator (A)
	    ; Converts 8 to 32 bits
	    or a
	    jp p, __PRINTU8
	    push af
	    call __PRINT_MINUS
	    pop af
	    neg
__PRINTU8:
	    PROC
	    LOCAL __PRINTU_LOOP
	    ld b, 0 ; Counter
__PRINTU_LOOP:
	    or a
	    jp z, __PRINTU_START
	    push bc
	    ld h, 10
	    call __DIVU8_FAST ; Divides by 10. D'E'H'L' contains modulo (L' since < 10)
	    pop bc
	    ld a, l
	    or '0'		  ; Stores ASCII digit (must be print in reversed order)
	    push af
	    ld a, h
	    inc b
	    jp __PRINTU_LOOP ; Uses JP in loops
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/printu8.asm"
#line 470 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/pstorestr2.asm"
; vim:ts=4:et:sw=4
	;
	; Stores an string (pointer to the HEAP by DE) into the address pointed
	; by (IX + BC). No new copy of the string is created into the HEAP, since
	; it's supposed it's already created (temporary string)
	;
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/storestr2.asm"
	; Similar to __STORE_STR, but this one is called when
	; the value of B$ if already duplicated onto the stack.
	; So we needn't call STRASSING to create a duplication
	; HL = address of string memory variable
	; DE = address of 2n string. It just copies DE into (HL)
	; 	freeing (HL) previously.
	    push namespace core
__PISTORE_STR2: ; Indirect store temporary string at (IX + BC)
	    push ix
	    pop hl
	    add hl, bc
__ISTORE_STR2:
	    ld c, (hl)  ; Dereferences HL
	    inc hl
	    ld h, (hl)
	    ld l, c		; HL = *HL (real string variable address)
__STORE_STR2:
	    push hl
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c		; HL = *HL (real string address)
	    push de
	    call __MEM_FREE
	    pop de
	    pop hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    dec hl		; HL points to mem address variable. This might be useful in the future.
	    ret
	    pop namespace
#line 9 "/zxbasic/src/lib/arch/zx48k/runtime/pstorestr2.asm"
	    push namespace core
__PSTORE_STR2:
	    push ix
	    pop hl
	    add hl, bc
	    jp __STORE_STR2
	    pop namespace
#line 471 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/spectranet.inc"
	;The MIT License
	;
	;Copyright (c) 2008 Dylan Smith
	;
	;Permission is hereby granted, free of charge, to any person obtaining a copy
	;of this software and associated documentation files (the "Software"), to deal
	;in the Software without restriction, including without limitation the rights
	;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
	;
	;The above copyright notice and this permission notice shall be included in
	;all copies or substantial portions of the Software.
	;
	;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	;THE SOFTWARE.
	; This file can be included in assembly language programs to give
	; symbolic access to the public jump table entry points.
	; Avoid double inclusion
	NAMESPACE Spectranet  ; NAME PREFIX to avoid naming clash
	; Hardware page-in entry points
	MODULECALL      equ $3FF8
	MODULECALL_NOPAGE       equ $28
	PAGEIN          equ $3FF9
	PAGEOUT         equ $007C
	HLCALL          equ $3FFA
	IXCALL          equ $3FFD
	; Port defines
	CTRLREG         equ $033B
	CPLDINFO        equ $023B
	; Jump table entry points
	SOCKET          equ $3E00      ; Allocate a socket
	CLOSE           equ $3E03      ; Close a socket
	LISTEN          equ $3E06      ; Listen for incoming connections
	ACCEPT          equ $3E09      ; Accept an incoming connection
	BIND            equ $3E0C      ; Bind a local address to a socket
	CONNECT         equ $3E0F      ; Connect to a remote host
	SEND            equ $3E12      ; Send data
	RECV            equ $3E15      ; Receive data
	SENDTO          equ $3E18      ; Send data to an address
	RECVFROM        equ $3E1B      ; Receive data from an address
	POLL            equ $3E1E      ; Poll a list of sockets
	POLLALL         equ $3E21      ; Poll all open sockets
	POLLFD          equ $3E24      ; Poll a single socket
	GETHOSTBYNAME   equ $3E27      ; Look up a hostname
	PUTCHAR42       equ $3E2A      ; 42 column print write a character
	PRINT42         equ $3E2D      ; 42 column print a null terminated string
	CLEAR42         equ $3E30      ; Clear the screen and reset 42-col print
	SETPAGEA        equ $3E33      ; Sets page area A
	SETPAGEB        equ $3E36      ; Sets page area B
	LONG2IPSTRING   equ $3E39      ; Convert a 4 byte big endian long to an IP
	IPSTRING2LONG   equ $3E3C      ; Convert an IP to a 4 byte big endian long
	ITOA8           equ $3E3F      ; Convert a byte to ascii
	RAND16          equ $3E42      ; 16 bit PRNG
	REMOTEADDRESS   equ $3E45      ; Fill struct sockaddr_in
	IFCONFIG_INET   equ $3E48      ; Set IPv4 address
	IFCONFIG_NETMASK equ $3E4B     ; Set netmask
	IFCONFIG_GW     equ $3E4E      ; Set gateway
	INITHW          equ $3E51      ; Set the MAC address and initial hw registers
	GETHWADDR       equ $3E54      ; Read the MAC address
	DECONFIG        equ $3E57      ; Deconfigure inet, netmask and gateway
	MAC2STRING      equ $3E5A      ; Convert 6 byte MAC address to a string
	STRING2MAC      equ $3E5D      ; Convert a hex string to a 6 byte MAC address
	ITOH8           equ $3E60      ; Convert accumulator to hex string
	HTOI8           equ $3E63      ; Convert hex string to byte in A
	GETKEY          equ $3E66      ; Get a key from the keyboard, and put it in A
	KEYUP           equ $3E69      ; Wait for key release
	INPUTSTRING     equ $3E6C      ; Read a string into buffer at DE
	GET_IFCONFIG_INET equ $3E6F    ; Gets the current IPv4 address
	GET_IFCONFIG_NETMASK equ $3E72 ; Gets the current netmask
	GET_IFCONFIG_GW equ $3E75      ; Gets the current gateway address
	SETTRAP         equ $3E78      ; Sets the programmable trap
	DISABLETRAP     equ $3E7B      ; Disables the programmable trap
	ENABLETRAP      equ $3E7E      ; Enables the programmable trap
	PUSHPAGEA       equ $3E81      ; Pages a page into area A, pushing the old one
	POPPAGEA        equ $3E84      ; Restores the previous page in area A
	PUSHPAGEB       equ $3E87      ; Pages into area B pushing the old one
	POPPAGEB        equ $3E8A      ; Restores the previous page in area B
	PAGETRAPRETURN  equ $3E8D      ; Returns from a trap to page area B
	TRAPRETURN      equ $3E90      ; Returns from a trap that didn't page area B
	ADDBASICEXT     equ $3E93      ; Adds a BASIC command
	STATEMENT_END   equ $3E96      ; Check for statement end, exit at syntax time
	EXIT_SUCCESS    equ $3E99      ; Use this to exit successfully after cmd
	PARSE_ERROR     equ $3E9C      ; Use this to exit to BASIC with a parse error
	RESERVEPAGE     equ $3E9F      ; Reserve a page of static RAM
	FREEPAGE        equ $3EA2      ; Free a page of static RAM
	REPORTERR       equ $3EA5      ; report an error via BASIC
	; Filesystem functions
	MOUNT           equ $3EA8
	UMOUNT          equ $3EAB
	OPENDIR         equ $3EAE
	OPEN            equ $3EB1
	UNLINK          equ $3EB4
	MKDIR           equ $3EB7
	RMDIR           equ $3EBA
	SIZE            equ $3EBD
	FREE            equ $3EC0
	STAT            equ $3EC3
	CHMOD           equ $3EC6
	READ            equ $3EC9
	WRITE           equ $3ECC
	LSEEK           equ $3ECF
	VCLOSE          equ $3ED2
	VPOLL           equ $3ED5
	READDIR         equ $3ED8
	CLOSEDIR        equ $3EDB
	CHDIR           equ $3EDE
	GETCWD          equ $3EE1
	RENAME          equ $3EE4
	SETMOUNTPOINT   equ $3EE7
	FREEMOUNTPOINT  equ $3EEA
	RESALLOC        equ $3EED
	; Definitions
	ALLOCFD         equ 1
	FREEFD          equ 0
	ALLOCDIRHND     equ 3
	FREEDIRHND      equ 2
	; POLL status bits
	BIT_RECV        equ 2
	BIT_DISCON      equ 1
	BIT_CONN        equ 0
	NAMESPACE DEFAULT           ; Clears namespace
#line 143 "/zxbasic/src/lib/arch/zx48k/runtime/spectranet.inc"
#line 472 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/strcat.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/strlen.asm"
	; Returns len if a string
	; If a string is NULL, its len is also 0
	; Result returned in HL
	    push namespace core
__STRLEN:	; Direct FASTCALL entry
	    ld a, h
	    or l
	    ret z
	    ld a, (hl)
	    inc hl
	    ld h, (hl)  ; LEN(str) in HL
	    ld l, a
	    ret
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/strcat.asm"
	    push namespace core
__ADDSTR:	; Implements c$ = a$ + b$
	    ; hl = &a$, de = &b$ (pointers)
__STRCAT2:	; This routine creates a new string in dynamic space
	    ; making room for it. Then copies a$ + b$ into it.
	    ; HL = a$, DE = b$
	    PROC
	    LOCAL __STR_CONT
	    LOCAL __STRCATEND
	    push hl
	    call __STRLEN
	    ld c, l
	    ld b, h		; BC = LEN(a$)
	    ex (sp), hl ; (SP) = LEN (a$), HL = a$
	    push hl		; Saves pointer to a$
	    inc bc
	    inc bc		; +2 bytes to store length
	    ex de, hl
	    push hl
	    call __STRLEN
	    ; HL = len(b$)
	    add hl, bc	; Total str length => 2 + len(a$) + len(b$)
	    ld c, l
	    ld b, h		; BC = Total str length + 2
	    call __MEM_ALLOC
	    pop de		; HL = c$, DE = b$
	    ex de, hl	; HL = b$, DE = c$
	    ex (sp), hl ; HL = a$, (SP) = b$
	    exx
	    pop de		; D'E' = b$
	    exx
	    pop bc		; LEN(a$)
	    ld a, d
	    or e
    ret z		; If no memory: RETURN
__STR_CONT:
	    push de		; Address of c$
	    ld a, h
	    or l
	    jr nz, __STR_CONT1 ; If len(a$) != 0 do copy
	    ; a$ is NULL => uses HL = DE for transfer
	    ld h, d
	    ld l, e
	    ld (hl), a	; This will copy 00 00 at (DE) location
	    inc de      ;
	    dec bc      ; Ensure BC will be set to 1 in the next step
__STR_CONT1:        ; Copies a$ (HL) into c$ (DE)
	    inc bc
	    inc bc		; BC = BC + 2
    ldir		; MEMCOPY: c$ = a$
	    pop hl		; HL = c$
	    exx
	    push de		; Recovers b$; A ex hl,hl' would be very handy
	    exx
	    pop de		; DE = b$
__STRCAT: ; ConCATenate two strings a$ = a$ + b$. HL = ptr to a$, DE = ptr to b$
    ; NOTE: Both DE, BC and AF are modified and lost
	    ; Returns HL (pointer to a$)
	    ; a$ Must be NOT NULL
	    ld a, d
	    or e
	    ret z		; Returns if de is NULL (nothing to copy)
	    push hl		; Saves HL to return it later
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    add hl, bc	; HL = end of (a$) string ; bc = len(a$)
	    push bc		; Saves LEN(a$) for later
	    ex de, hl	; DE = end of string (Begin of copy addr)
	    ld c, (hl)
	    inc hl
	    ld b, (hl)	; BC = len(b$)
	    ld a, b
	    or c
	    jr z, __STRCATEND; Return if len(b$) == 0
	    push bc			 ; Save LEN(b$)
	    inc hl			 ; Skip 2nd byte of len(b$)
	    ldir			 ; Concatenate b$
	    pop bc			 ; Recovers length (b$)
	    pop hl			 ; Recovers length (a$)
	    add hl, bc		 ; HL = LEN(a$) + LEN(b$) = LEN(a$+b$)
	    ex de, hl		 ; DE = LEN(a$+b$)
	    pop hl
	    ld (hl), e		 ; Updates new LEN and return
	    inc hl
	    ld (hl), d
	    dec hl
	    ret
__STRCATEND:
	    pop hl		; Removes Len(a$)
	    pop hl		; Restores original HL, so HL = a$
	    ret
	    ENDP
	    pop namespace
#line 473 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/string.asm"
	; String library
	    push namespace core
__STR_ISNULL:	; Returns A = FF if HL is 0, 0 otherwise
	    ld a, h
	    or l
	    sub 1		; Only CARRY if HL is NULL
	    sbc a, a	; Only FF if HL is NULL (0 otherwise)
	    ret
__STRCMP:	; Compares strings at HL (a$), DE (b$)
	            ; Returns 0 if EQual, -1 if HL < DE, +1 if HL > DE
	    ; A register is preserved and returned in A'
	    PROC ; __FASTCALL__
	    LOCAL __STRCMPZERO
	    LOCAL __STRCMPEXIT
	    LOCAL __STRCMPLOOP
	    LOCAL __EQULEN1
	    LOCAL __HLZERO
	    ex af, af'	; Saves current A register in A' (it's used by STRXX comparison functions)
	    push hl
	    call __STRLEN
	    ld a, h
	    or l
	    pop hl
	    jr z, __HLZERO  ; if HL == "", go to __HLZERO
	    push de
	    ex de, hl
	    call __STRLEN
	    ld a, h
	    or l
	    ld a, 1
	    ex de, hl   ; Recovers HL
	    pop de
	    ret z		; Returns +1 if HL != "" AND DE == ""
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl		; BC = LEN(a$)
	    push hl		; HL = &a$, saves it
	    ex de, hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ex de, hl	; HL = LEN(b$), de = &b$
	    ; At this point Carry is cleared, and A reg. = 1
	    sbc hl, bc	     ; Carry if len(a$)[BC] > len(b$)[HL]
	    ld a, 0
    jr z, __EQULEN1	 ; Jumps if len(a$)[BC] = len(b$)[HL] : A = 0
	    dec a
    jr nc, __EQULEN1 ; Jumps if len(a$)[BC] < len(b$)[HL] : A = 1
	    adc hl, bc  ; Restores HL
    ld a, 1     ; Signals len(a$)[BC] > len(b$)[HL] : A = 1
	    ld b, h
	    ld c, l
__EQULEN1:
	    pop hl		; Recovers A$ pointer
	    push af		; Saves A for later (Value to return if strings reach the end)
	    ld a, b
	    or c
	    jr z, __STRCMPZERO ; empty string being compared
    ; At this point: BC = lesser length, DE and HL points to b$ and a$ chars respectively
__STRCMPLOOP:
	    ld a, (de)
	    cpi
	    jr nz, __STRCMPEXIT ; (HL) != (DE). Examine carry
	    jp po, __STRCMPZERO ; END of string (both are equal)
	    inc de
	    jp __STRCMPLOOP
__STRCMPZERO:
	    pop af		; This is -1 if len(a$) < len(b$), +1 if len(b$) > len(a$), 0 otherwise
	    ret
__STRCMPEXIT:		; Sets A with the following value
	    dec hl		; Get back to the last char
	    cp (hl)
	    sbc a, a	; A = -1 if carry => (DE) < (HL); 0 otherwise (DE) > (HL)
	    cpl			; A = -1 if (HL) < (DE), 0 otherwise
	    add a, a    ; A = A * 2 (thus -2 or 0)
	    inc a		; A = A + 1 (thus -1 or 1)
	    pop bc		; Discard top of the stack
	    ret
__HLZERO:
	    ex de, hl
	    call __STRLEN
	    ld a, h
	    or l
	    ret z		; Returns 0 (EQ) if HL == DE == ""
	    ld a, -1
	    ret			; Returns -1 if HL == "" and DE != ""
	    ENDP
	    ; The following routines perform string comparison operations (<, >, ==, etc...)
	    ; On return, A will contain 0 for False, other value for True
	    ; Register A' will determine whether the incoming strings (HL, DE) will be freed
    ; from dynamic memory on exit:
	    ;		Bit 0 => 1 means HL will be freed.
	    ;		Bit 1 => 1 means DE will be freed.
__STREQ:	; Compares a$ == b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    sub 1
	    sbc a, a    ; 0 if A register was 0, 0xFF if A was 1 or -1
	    jp __FREE_STR
__STRNE:	; Compares a$ != b$ (HL = ptr a$, DE = ptr b$). Returns 1 (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    jp __FREE_STR
__STRLT:	; Compares a$ < b$ (HL = ptr a$, DE = ptr b$). Returns FE (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    or a
	    jp z, __FREE_STR ; Returns 0 if A == B
	    dec a		; Returns 0 if A == 1 => a$ > b$
	    jp __FREE_STR
__STRLE:	; Compares a$ <= b$ (HL = ptr a$, DE = ptr b$). Returns FF or FE (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    dec a		; Returns 0 if A == 1 => a$ < b$
	    jp __FREE_STR
__STRGT:	; Compares a$ > b$ (HL = ptr a$, DE = ptr b$). Returns 2 (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    or a
	    jp z, __FREE_STR		; Returns 0 if A == B
	    inc a		; Returns 0 if A == -1 => a$ < b$
	    jp __FREE_STR
__STRGE:	; Compares a$ >= b$ (HL = ptr a$, DE = ptr b$). Returns 1 or 2 (True) or 0 (False)
	    push hl
	    push de
	    call __STRCMP
	    pop de
	    pop hl
	    inc a		; Returns 0 if A == -1 => a$ < b$
__FREE_STR: ; This exit point will test A' for bits 0 and 1
	    ; If bit 0 is 1 => Free memory from HL pointer
	    ; If bit 1 is 1 => Free memory from DE pointer
	    ; Finally recovers A, to return the result
	    PROC
	    LOCAL __FREE_STR2
	    LOCAL __FREE_END
	    ;; normalize boolean
	    sub 1
	    sbc a, a
	    inc a
	    ex af, af'
	    bit 0, a
	    jr z, __FREE_STR2
	    push af
	    push de
	    call __MEM_FREE
	    pop de
	    pop af
__FREE_STR2:
	    bit 1, a
	    jr z, __FREE_END
	    ex de, hl
	    call __MEM_FREE
__FREE_END:
	    ex af, af'
	    ret
	    ENDP
	    pop namespace
#line 474 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/strslice.asm"
	; String slicing library
	; HL = Str pointer
	; DE = String start
	; BC = String character end
	; A register => 0 => the HL pointer wont' be freed from the HEAP
	; e.g. a$(5 TO 10) => HL = a$; DE = 5; BC = 10
	; This implements a$(X to Y) being X and Y first and
	; last characters respectively. If X > Y, NULL is returned
	; Otherwise returns a pointer to a$ FROM X to Y (starting from 0)
	; if Y > len(a$), then a$ will be padded with spaces (reallocating
	; it in dynamic memory if needed). Returns pointer (HL) to resulting
	; string. NULL (0) if no memory for padding.
	;
	    push namespace core
__STRSLICE:			; Callee entry
	    pop hl			; Return ADDRESS
	    pop bc			; Last char pos
	    pop de			; 1st char pos
	    ex (sp), hl		; CALLEE. -> String start
__STRSLICE_FAST:	; __FASTCALL__ Entry
	    PROC
	    LOCAL __CONT
	    LOCAL __EMPTY
	    LOCAL __FREE_ON_EXIT
	    push hl			; Stores original HL pointer to be recovered on exit
	    ex af, af'		; Saves A register for later
	    push hl
	    call __STRLEN
	    inc bc			; Last character position + 1 (string starts from 0)
	    or a
	    sbc hl, bc		; Compares length with last char position
	    jr nc, __CONT	; If Carry => We must copy to end of string
	    add hl, bc		; Restore back original LEN(a$) in HL
	    ld b, h
	    ld c, l			; Copy to the end of str
	    ccf				; Clears Carry flag for next subtraction
__CONT:
	    ld h, b
	    ld l, c			; HL = Last char position to copy (1 for char 0, 2 for char 1, etc)
	    sbc hl, de		; HL = LEN(a$) - DE => Number of chars to copy
	    jr z, __EMPTY	; 0 Chars to copy => Return HL = 0 (NULL STR)
	    jr c, __EMPTY	; If Carry => Nothing to return (NULL STR)
	    ld b, h
	    ld c, l			; BC = Number of chars to copy
	    inc bc
	    inc bc			; +2 bytes for string length number
	    push bc
	    push de
	    call __MEM_ALLOC
	    pop de
	    pop bc
	    ld a, h
	    or l
	    jr z, __EMPTY	; Return if NULL (no memory)
	    dec bc
	    dec bc			; Number of chars to copy (Len of slice)
	    ld (hl), c
	    inc hl
	    ld (hl), b
	    inc hl			; Stores new string length
	    ex (sp), hl		; Pointer to A$ now in HL; Pointer to new string chars in Stack
	    inc hl
	    inc hl			; Skip string length
	    add hl, de		; Were to start from A$
	    pop de			; Start of new string chars
	    push de			; Stores it again
	    ldir			; Copies BC chars
	    pop de
	    dec de
	    dec de			; Points to String LEN start
	    ex de, hl		; Returns it in HL
	    jr __FREE_ON_EXIT
__EMPTY:			; Return NULL (empty) string
	    pop hl
	    ld hl, 0		; Return NULL
__FREE_ON_EXIT:
	    ex af, af'		; Recover original A register
	    ex (sp), hl		; Original HL pointer
	    or a
	    call nz, __MEM_FREE
	    pop hl			; Recover result
	    ret
	    ENDP
	    pop namespace
#line 476 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
.LABEL.__LABEL38:
	DEFB 00h
	DEFB 00h
	DEFB 02h
	END
