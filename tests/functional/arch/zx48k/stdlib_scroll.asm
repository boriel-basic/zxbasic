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
#line 25 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1
		LOCAL LOOP2
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		srl a
		srl a
		srl a
		inc a
		ld e, a
		ld a, h
		sub b
		ret c
		inc a
		ld d, a
		ld b, h
		ld a, 191
		LOCAL __PIXEL_ADDR
		__PIXEL_ADDR EQU 22ACh
		call __PIXEL_ADDR
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
LOOP1:
		push hl
		ld b, e
		or a
LOOP2:
		rr (hl)
		inc hl
		djnz LOOP2
		pop hl
		dec d
		ret z
		call SP.PixelDown
		jp LOOP1
		ENDP
		pop namespace
#line 83 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollRight__leave:
	ret
_ScrollLeft:
#line 92 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1
		LOCAL LOOP2
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		srl a
		srl a
		srl a
		inc a
		ld e, a
		ld a, h
		sub b
		ret c
		ld c, d
		inc a
		ld d, a
		ld b, h
		ld a, 191
		LOCAL __PIXEL_ADDR
		__PIXEL_ADDR EQU 22ACh
		call __PIXEL_ADDR
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
LOOP1:
		push hl
		ld b, e
		or a
LOOP2:
		rl (hl)
		dec hl
		djnz LOOP2
		pop hl
		dec d
		ret z
		call SP.PixelDown
		jp LOOP1
		ENDP
		pop namespace
#line 151 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollLeft__leave:
	ret
_ScrollUp:
#line 160 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		srl a
		srl a
		srl a
		inc a
		ld e, a
		ex af, af'
		ld a, h
		sub b
		ret c
		inc a
		ld d, a
		ld b, h
		ld a, 191
		LOCAL __PIXEL_ADDR
		__PIXEL_ADDR EQU 22ACh
		call __PIXEL_ADDR
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld a, d
		ld b, 0
		exx
		ld b, a
		ex af, af'
		ld c, a
		jp LOOP_START
LOOP1:
		exx
		ld d, h
		ld e, l
		ld c, a
		call SP.PixelDown
		push hl
		ldir
		pop hl
		exx
		ld a, c
		LOCAL LOOP_START
LOOP_START:
		djnz LOOP1
		exx
		ld (hl), 0
		ld d, h
		ld e, l
		inc de
		ld c, a
		dec c
		ret z
		ldir
		ENDP
		pop namespace
#line 237 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
_ScrollUp__leave:
	ret
_ScrollDown:
#line 246 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
		push namespace core
		PROC
		LOCAL LOOP1
		pop hl
		pop bc
		pop de
		ex (sp), hl
		ld c, a
		ld a, d
		sub c
		ret c
		srl a
		srl a
		srl a
		inc a
		ld e, a
		ex af, af'
		ld a, h
		sub b
		ret c
		inc a
		ld d, a
		ld a, 191
		LOCAL __PIXEL_ADDR
		__PIXEL_ADDR EQU 22ACh
		call __PIXEL_ADDR
		res 6, h
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld a, d
		ld b, 0
		exx
		ld b, a
		ex af, af'
		ld c, a
		jp LOOP_START
LOOP1:
		exx
		ld d, h
		ld e, l
		ld c, a
		call SP.PixelUp
		push hl
		ldir
		pop hl
		exx
		ld a, c
		LOCAL LOOP_START
LOOP_START:
		djnz LOOP1
		exx
		ld (hl), 0
		ld d, h
		ld e, l
		inc de
		ld c, a
		dec c
		ret z
		ldir
		ENDP
		pop namespace
#line 323 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
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
#line 328 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
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
#line 329 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/cls.asm"
	;; Clears the user screen (24 rows)
	    push namespace core
CLS:
	    PROC
	    ld hl, 0
	    ld (COORDS), hl
	    ld hl, SCR_SIZE
	    ld (S_POSN), hl
	    ld hl, (SCREEN_ADDR)
	    ld (DFCC), hl
	    ld (hl), 0
	    ld d, h
	    ld e, l
	    inc de
	    ld bc, 6143
	    ldir
	    ; Now clear attributes
	    ld hl, (SCREEN_ATTR_ADDR)
	    ld (DFCCL), hl
	    ld d, h
	    ld e, l
	    inc de
	    ld a, (ATTR_P)
	    ld (hl), a
	    ld bc, 767
	    ldir
	    ret
	    ENDP
	    pop namespace
#line 330 "/zxbasic/src/lib/arch/zx48k/stdlib/scroll.bas"
	END
