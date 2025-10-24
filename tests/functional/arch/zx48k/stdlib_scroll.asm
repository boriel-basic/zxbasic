	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
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
_ScrollRight:
#line 26 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1, LOOP2, MASK1, MASK2, COLUMNN, NEQ1
		LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		ld a, h
		sub b
		ret c
		inc a
		ld e, a
		ld a,c
		and 7
		inc a
		ld b,a
		xor a
MASK1:
		rra
		scf
		djnz MASK1
		ld (AND1+1),a
		ld (AND5+1),a
		cpl
		ld (AND2+1),a
		ld (AND7+1),a
		ld a,d
		and 7
		inc a
		ld b,a
		xor a
MASK2:
		scf
		rra
		djnz MASK2
		ld (AND4+1),a
		ld (AND8+1),a
		cpl
		ld (AND3+1),a
		ld (AND6+1),a
		ld a,c
		and %11111000
		rrca
		rrca
		rrca
		ld b,a
		ld a,d
		and %11111000
		rrca
		rrca
		rrca
		sub b
		ex af,af'
		ld b, h
		ld a, 191
		call 22ACh
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ex af,af'
		jr z,NEQ1
		dec a
		ld d,a
LOOP1:
		push hl
		ld a,(hl)
AND1:
		and %11100000
		ld c,a
		ld a,(hl)
AND2:
		and %00011111
		rra
		rl b
		or c
		ld (hl),a
		inc hl
		ld a,d
		and a
		jr z,COLUMNN
		rr b
		ld b,a
LOOP2:
		rr (hl)
		inc hl
		djnz LOOP2
		rl b
COLUMNN:
		ld a,(hl)
AND3:
		and %00000011
		ld c,a
		ld a,(hl)
		rr b
		rra
AND4:
		and %11111100
		or c
		ld (hl),a
		pop hl
		dec e
		ret z
		call SP.PixelDown
		jp LOOP1
NEQ1:
		ld b,(hl)
		ld a,b
AND5:
		and %11100000
		ld c,a
		ld a,b
AND6:
		and %00000011
		or c
		ld c,a
		ld a,b
AND7:
		and %00011111
		rra
AND8:
		and %11111100
		or c
		ld (hl),a
		dec e
		ret z
		call SP.PixelDown
		jp NEQ1
		ENDP
		pop namespace
#line 187 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollRight__leave:
	ret
_ScrollLeft:
#line 195 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1, LOOP2, MASK1, MASK2, COLUMN1, NEQ1
		LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		ld a, h
		sub b
		ret c
		inc a
		ld e, a
		ld a,c
		and 7
		inc a
		ld b,a
		xor a
MASK1:
		rra
		scf
		djnz MASK1
		ld (AND3+1),a
		ld (AND6+1),a
		cpl
		ld (AND4+1),a
		ld (AND8+1),a
		ld a,d
		and 7
		inc a
		ld b,a
		xor a
MASK2:
		scf
		rra
		djnz MASK2
		ld (AND2+1),a
		ld (AND7+1),a
		cpl
		ld (AND1+1),a
		ld (AND5+1),a
		ld a,c
		and %11111000
		rrca
		rrca
		rrca
		ld b,a
		ld a,d
		and %11111000
		rrca
		rrca
		rrca
		sub b
		ex af,af'
		ld c, d
		ld b, h
		ld a, 191
		call 22ACh
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ex af,af'
		jr z,NEQ1
		dec a
		ld d,a
LOOP1:
		push hl
		ld a,(hl)
AND1:
		and %00000011
		ld c,a
		ld a,(hl)
AND2:
		and %11111100
		rla
		rl b
		or c
		ld (hl),a
		dec hl
		ld a,d
		and a
		jr z,COLUMN1
		rr b
		ld b,a
LOOP2:
		rl (hl)
		dec hl
		djnz LOOP2
		rl b
COLUMN1:
		ld a,(hl)
AND3:
		and %11100000
		ld c,a
		ld a,(hl)
		rr b
		rla
AND4:
		and %00011111
		or c
		ld (hl),a
		pop hl
		dec e
		ret z
		call SP.PixelDown
		jp LOOP1
NEQ1:
		ld b,(hl)
		ld a,b
AND5:
		and %00000011
		ld c,a
		ld a,b
AND6:
		and %11100000
		or c
		ld c,a
		ld a,b
AND7:
		and %11111100
		rla
AND8:
		and %00011111
		or c
		ld (hl),a
		dec e
		ret z
		call SP.PixelDown
		jp NEQ1
		ENDP
		pop namespace
#line 357 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollLeft__leave:
	ret
_ScrollUp:
#line 366 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1, MASK1, MASK2, COLUMNN, NEQ1
		LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
		LOCAL EMPTYLINE
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		ld a, h
		sub b
		ret c
		push ix
		inc a
		ld ixL,a
		ld a,c
		and 7
		inc a
		ld b,a
		xor a
MASK1:
		rra
		scf
		djnz MASK1
		ld (AND1+1),a
		ld (AND5+1),a
		cpl
		ld (AND2+1),a
		ld (AND7+1),a
		ld a,d
		and 7
		inc a
		ld b,a
		xor a
MASK2:
		scf
		rra
		djnz MASK2
		ld (AND4+1),a
		ld (AND8+1),a
		cpl
		ld (AND3+1),a
		ld (AND6+1),a
		ld a,c
		and %11111000
		rrca
		rrca
		rrca
		ld b,a
		ld a,d
		and %11111000
		rrca
		rrca
		rrca
		sub b
		ex af,af'
		ld b, h
		ld a, 191
		call 22ACh
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ex af,af'
		jr z,NEQ1
		dec a
		ld ixH,a
		ld b,0
LOOP1:
		dec ixL
		ld d,h
		ld e,l
		call z,EMPTYLINE
		call nz,SP.PixelDown
		inc ixL
		push hl
		ld a,(hl)
AND2:
		and %00011111
		ld c,a
		ld a,(de)
AND1:
		and %11100000
		or c
		ld (de),a
		inc hl
		inc de
		ld a,ixH
		and a
		jr z,COLUMNN
		ld c,a
		ldir
COLUMNN:
		ld a,(hl)
AND4:
		and %11111100
		ld c,a
		ld a,(de)
AND3:
		and %00000011
		or c
		ld (de),a
		pop hl
		dec ixL
		jp nz,LOOP1
		pop ix
		ret
NEQ1:
		dec ixL
		ld d,h
		ld e,l
		call z,EMPTYLINE
		call nz,SP.PixelDown
		inc ixL
		ld a,(hl)
AND7:
		and %00011111
AND8:
		and %11111100
		ld c,a
		ld a,(de)
AND5:
		and %11100000
		ld b,a
		ld a,(de)
AND6:
		and %00000011
		or b
		or c
		ld (de),a
		dec ixL
		jp nz,NEQ1
		pop ix
		ret
		defs 32,0
EMPTYLINE:
		ld hl,EMPTYLINE-32
		ENDP
		pop namespace
#line 537 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollUp__leave:
	ret
_ScrollDown:
#line 546 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1, MASK1, MASK2, COLUMNN, NEQ1
		LOCAL AND1, AND2, AND3, AND4, AND5, AND6, AND7, AND8
		LOCAL EMPTYLINE
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		ld a, h
		sub b
		ret c
		push ix
		inc a
		ld ixL,a
		ld h,b
		ld a,c
		and 7
		inc a
		ld b,a
		xor a
MASK1:
		rra
		scf
		djnz MASK1
		ld (AND1+1),a
		ld (AND5+1),a
		cpl
		ld (AND2+1),a
		ld (AND7+1),a
		ld a,d
		and 7
		inc a
		ld b,a
		xor a
MASK2:
		scf
		rra
		djnz MASK2
		ld (AND4+1),a
		ld (AND8+1),a
		cpl
		ld (AND3+1),a
		ld (AND6+1),a
		ld a,c
		and %11111000
		rrca
		rrca
		rrca
		ld b,a
		ld a,d
		and %11111000
		rrca
		rrca
		rrca
		sub b
		ex af,af'
		ld b, h
		ld a, 191
		call 22ACh
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ex af,af'
		jr z,NEQ1
		dec a
		ld ixH,a
		ld b,0
LOOP1:
		dec ixL
		ld d,h
		ld e,l
		call z,EMPTYLINE
		call nz,SP.PixelUp
		inc ixL
		push hl
		ld a,(hl)
AND2:
		and %00011111
		ld c,a
		ld a,(de)
AND1:
		and %11100000
		or c
		ld (de),a
		inc hl
		inc de
		ld a,ixH
		and a
		jr z,COLUMNN
		ld c,a
		ldir
COLUMNN:
		ld a,(hl)
AND4:
		and %11111100
		ld c,a
		ld a,(de)
AND3:
		and %00000011
		or c
		ld (de),a
		pop hl
		dec ixL
		jp nz,LOOP1
		pop ix
		ret
NEQ1:
		dec ixL
		ld d,h
		ld e,l
		call z,EMPTYLINE
		call nz,SP.PixelUp
		inc ixL
		ld a,(hl)
AND7:
		and %00011111
AND8:
		and %11111100
		ld c,a
		ld a,(de)
AND5:
		and %11100000
		ld b,a
		ld a,(de)
AND6:
		and %00000011
		or b
		or c
		ld (de),a
		dec ixL
		jp nz,NEQ1
		pop ix
		ret
		defs 32,0
EMPTYLINE:
		ld hl,EMPTYLINE-32
		ENDP
		pop namespace
#line 718 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollDown__leave:
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/SP/PixelDown.asm"
	;
	; PixelDown
	; Alvin Albrecht 2002
	;
	; Pixel Down
	;
	; Adjusts screen address HL to move one pixel down in the display.
	; (0,0) is located at the top left corner of the screen.
	;
; enter: HL = valid screen address
; exit : Carry = moved off screen
	;        Carry'= moved off current cell (needs ATTR update)
	;        HL = moves one pixel down
; used : AF, HL
	    push namespace core
SP.PixelDown:
	    PROC
	    LOCAL leave
	    push de
	    ld de, (SCREEN_ADDR)
	    or a
	    sbc hl, de
	    inc h
	    ld a,h
	    and $07
	    jr nz, leave
	    scf         ;  Sets carry on F', which flags ATTR must be updated
	    ex af, af'
	    ld a,h
	    sub $08
	    ld h,a
	    ld a,l
	    add a,$20
	    ld l,a
	    jr nc, leave
	    ld a,h
	    add a,$08
	    ld h,a
	    cp $19     ; carry = 0 => Out of screen
	    jr c, leave ; returns if out of screen
	    ccf
	    pop de
	    ret
leave:
	    add hl, de ; This always sets Carry = 0
	    pop de
	    ret
	    ENDP
	    pop namespace
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
#line 58 "/zxbasic/src/lib/arch/zx48k/runtime/SP/PixelDown.asm"
#line 723 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/SP/PixelUp.asm"
	;
	; PixelUp
	; Alvin Albrecht 2002
	;
	; Pixel Up
	;
	; Adjusts screen address HL to move one pixel up in the display.
	; (0,0) is located at the top left corner of the screen.
	;
; enter: HL = valid screen address
; exit : Carry = moved off screen
	;        HL = moves one pixel up
; used : AF, HL
	    push namespace core
SP.PixelUp:
	    PROC
	    LOCAL leave
	    push de
	    ld de, (SCREEN_ADDR)
	    or a
	    sbc hl, de
	    ld a,h
	    dec h
	    and $07
	    jr nz, leave
	    scf         ; sets C' to 1 (ATTR update needed)
	    ex af, af'
	    ld a,$08
	    add a,h
	    ld h,a
	    ld a,l
	    sub $20
	    ld l,a
	    jr nc, leave
	    ld a,h
	    sub $08
	    ld h,a
leave:
	    push af
	    add hl, de
	    pop af
	    pop de
	    ret
	    ENDP
	    pop namespace
#line 724 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
	END
