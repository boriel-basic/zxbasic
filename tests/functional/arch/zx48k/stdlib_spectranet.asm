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
	call .core.__MEM_INIT
	call .core.__PRINT_INIT
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
.core.ZXBASIC_HEAP_SIZE EQU 4768
.core.ZXBASIC_MEM_HEAP:
	DEFS 4768
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
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
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
	ld hl, 0
	push hl
	push hl
	push hl
	ld hl, -6
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
	ld l, (ix-4)
	ld h, (ix-3)
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
	ld l, (ix-4)
	ld h, (ix-3)
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
	ld l, (ix-4)
	ld h, (ix-3)
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
	ld l, (ix-4)
	ld h, (ix-3)
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
	ld l, (ix-4)
	ld h, (ix-3)
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
	ld de, -6
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
	ld l, (ix-4)
	ld h, (ix-3)
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
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
#line 20 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
#line 24 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
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
	LBOUND_PTR EQU 23698           ; Uses MEMBOT as a temporary variable
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
#line 66 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
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
#line 116 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
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
	    call __FNMUL        ; HL <= HL * DE mod 65536
	    jp LOOP
ARRAY_END:
	    ld a, (hl)
	    exx
#line 146 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 156 "/zxbasic/src/lib/arch/zx48k/runtime/array.asm"
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
	    ;; Performs a faster multiply for little 16bit numbs
	    LOCAL __FNMUL, __FNMUL2
__FNMUL:
	    xor a
	    or h
	    jp nz, __MUL16_FAST
	    or l
	    ret z
	    cp 33
	    jp nc, __MUL16_FAST
	    ld b, l
	    ld l, h  ; HL = 0
__FNMUL2:
	    add hl, de
	    djnz __FNMUL2
	    ret
	    ENDP
	    pop namespace
#line 458 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/arrayalloc.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/calloc.asm"
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
	ERR_NR    EQU    23610    ; Error code system variable
	; Error code definitions (as in ZX spectrum manual)
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
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
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
	    pop namespace
#line 69 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/heapinit.asm"
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
#line 70 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
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
#line 113 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
	    ret z ; NULL
#line 115 "/zxbasic/src/lib/arch/zx48k/runtime/alloc.asm"
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
#line 13 "/zxbasic/src/lib/arch/zx48k/runtime/calloc.asm"
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
#line 3 "/zxbasic/src/lib/arch/zx48k/runtime/arrayalloc.asm"
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
	;  with 0 bytes
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
#line 139 "/zxbasic/src/lib/arch/zx48k/runtime/arrayalloc.asm"
	    pop namespace
#line 459 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/asc.asm"
	; Returns the ascii code for the given str
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/free.asm"
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
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
; vim:ts=4:sw=4:et:
	; PRINT command routine
	; Does not print attribute. Use PRINT_STR or PRINT_NUM for that
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/sposn.asm"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/sysvars.asm"
	;; -----------------------------------------------------------------------
	;; ZX Basic System Vars
	;; Some of them will be mapped over Sinclair ROM ones for compatibility
	;; -----------------------------------------------------------------------
	push namespace core
SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)
	; These are mapped onto ZX Spectrum ROM VARS
	CHARS               EQU 23606  ; Pointer to ROM/RAM Charset
	TV_FLAG             EQU 23612  ; Flags for controlling output to screen
	UDG                 EQU 23675  ; Pointer to UDG Charset
	COORDS              EQU 23677  ; Last PLOT coordinates
	FLAGS2              EQU 23681  ;
	ECHO_E              EQU 23682  ;
	DFCC                EQU 23684  ; Next screen addr for PRINT
	DFCCL               EQU 23686  ; Next screen attr for PRINT
	S_POSN              EQU 23688
	ATTR_P              EQU 23693  ; Current Permanent ATTRS set with INK, PAPER, etc commands
	ATTR_T              EQU 23695  ; temporary ATTRIBUTES
	P_FLAG              EQU 23697  ;
	MEM0                EQU 23698  ; Temporary memory buffer used by ROM chars
	SCR_COLS            EQU 33     ; Screen with in columns + 1
	SCR_ROWS            EQU 24     ; Screen height in rows
	SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS
	pop namespace
#line 2 "/zxbasic/src/lib/arch/zx48k/runtime/sposn.asm"
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
#line 6 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 8 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 9 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 10 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 11 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 12 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 13 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 14 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 15 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 16 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
	    jr c, __PRINT_SPECIAL    ; Characters below ' ' are special ones
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
#line 94 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
	PO_GR_1 EQU 0B38h
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
	    bit 2, (iy + $47)
	    call nz, __BOLD
#line 141 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
	    bit 4, (iy + $47)
	    call nz, __ITALIC
#line 146 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 211 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
	    jr __PRINT_RESTART
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
	    jr __PRINT_RESTART
__PRINT_PAP:
	    ld hl, __PRINT_PAP2
	    jr __PRINT_SET_STATE
__PRINT_PAP2:
	    call PAPER_TMP
	    jr __PRINT_RESTART
__PRINT_FLA:
	    ld hl, __PRINT_FLA2
	    jr __PRINT_SET_STATE
__PRINT_FLA2:
	    call FLASH_TMP
	    jr __PRINT_RESTART
__PRINT_BRI:
	    ld hl, __PRINT_BRI2
	    jr __PRINT_SET_STATE
__PRINT_BRI2:
	    call BRIGHT_TMP
	    jr __PRINT_RESTART
__PRINT_INV:
	    ld hl, __PRINT_INV2
	    jr __PRINT_SET_STATE
__PRINT_INV2:
	    call INVERSE_TMP
	    jr __PRINT_RESTART
__PRINT_OVR:
	    ld hl, __PRINT_OVR2
	    jr __PRINT_SET_STATE
__PRINT_OVR2:
	    call OVER_TMP
	    jr __PRINT_RESTART
__PRINT_BOLD:
	    ld hl, __PRINT_BOLD2
	    jp __PRINT_SET_STATE
__PRINT_BOLD2:
	    call BOLD_TMP
	    jp __PRINT_RESTART
#line 355 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
__PRINT_ITA:
	    ld hl, __PRINT_ITA2
	    jp __PRINT_SET_STATE
__PRINT_ITA2:
	    call ITALIC_TMP
	    jp __PRINT_RESTART
#line 365 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 386 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 414 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
	    LOCAL __SCROLL_SCR
#line 488 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
	__SCROLL_SCR EQU 0DFEh  ; Use ROM SCROLL
#line 490 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
#line 491 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 547 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
	    LOCAL __PRINT_BOLD2
#line 553 "/zxbasic/src/lib/arch/zx48k/runtime/print.asm"
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
#line 467 "/zxbasic/src/lib/arch/zx48k/stdlib/spectranet.bas"
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
