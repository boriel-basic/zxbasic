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
_putChars:
	push ix
	ld ix, 0
	add ix, sp
#line 34 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
		PROC
		LOCAL BLPutChar, BLPutCharColumnLoop, BLPutCharInColumnLoop, BLPutCharSameThird
		LOCAL BLPutCharNextThird, BLPutCharNextColumn, BLPutCharsEnd
BLPutChar:
		ld      a,(ix+5)
		ld      l,a
		ld      a,(ix+7)
		ld      d,a
		and     24
		ld      h,a
		ld      a,d
		and     7
		rrca
		rrca
		rrca
		or      l
		ld      l,a
		push hl
		ld e,(ix+12)
		ld d,(ix+13)
		ld b,(ix+9)
		push bc
BLPutCharColumnLoop:
		ld b, (ix+11)
BLPutCharInColumnLoop:
		push hl
		push de
		ld de, (.core.SCREEN_ADDR)
		add hl, de
		pop de
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		inc de
		inc h
		ld a,(de)
		ld (hl),a
		pop hl
		inc de
		dec b
		jr z, BLPutCharNextColumn
		push de
		ld   a,l
		and  224
		cp   224
		jr   z,BLPutCharNextThird
BLPutCharSameThird:
		ld   de,32
		add  hl,de
		pop de
		jp BLPutCharInColumnLoop
BLPutCharNextThird:
		ld de,1824
		add hl,de
		pop de
		jp BLPutCharInColumnLoop
BLPutCharNextColumn:
		pop bc
		pop hl
		dec b
		jr z, BLPutCharsEnd
		inc l
		push hl
		push bc
		jp BLPutCharColumnLoop
BLPutCharsEnd:
		ENDP
#line 148 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
_putChars__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_paint:
	push ix
	ld ix, 0
	add ix, sp
#line 167 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
		PROC
		LOCAL BLPaintHeightLoop, BLPaintWidthLoop, BLPaintWidthExitLoop, BLPaintHeightExitLoop
		ld      a,(ix+7)
		rrca
		rrca
		rrca
		ld      l,a
		and     3
		ld      h,a
		ld      a,l
		and     224
		ld      l,a
		ld      a,(ix+5)
		add     a,l
		ld      l,a
		ld      de,(.core.SCREEN_ATTR_ADDR)
		add     hl, de
		push hl
		ld a, (ix+13)
		ld de,32
		ld c,(ix+11)
BLPaintHeightLoop:
		ld b,(ix+9)
BLPaintWidthLoop:
		ld (hl),a
		inc hl
		djnz BLPaintWidthLoop
BLPaintWidthExitLoop:
		pop hl
		dec c
		jr z, BLPaintHeightExitLoop
		add hl,de
		push hl
		jp BLPaintHeightLoop
BLPaintHeightExitLoop:
		ENDP
#line 212 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
_paint__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_paintData:
	push ix
	ld ix, 0
	add ix, sp
#line 232 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
		PROC
		LOCAL BLPaintDataHeightLoop, BLPaintDataWidthLoop, BLPaintDataWidthExitLoop, BLPaintDataHeightExitLoop
		ld      a,(ix+7)
		rrca
		rrca
		rrca
		ld      l,a
		and     3
		ld      h,a
		ld      a,l
		and     224
		ld      l,a
		ld      a,(ix+5)
		add     a,l
		ld      l,a
		ld      de,(.core.SCREEN_ATTR_ADDR)
		add     hl, de
		push hl
		ld d,(ix+13)
		ld e,(ix+12)
		ld c,(ix+11)
BLPaintDataHeightLoop:
		ld b,(ix+9)
BLPaintDataWidthLoop:
		ld a,(de)
		ld (hl),a
		inc hl
		inc de
		djnz BLPaintDataWidthLoop
BLPaintDataWidthExitLoop:
		pop hl
		dec c
		jr z, BLPaintDataHeightExitLoop
		push de
		ld de,32
		add hl,de
		pop de
		push hl
		jp BLPaintDataHeightLoop
BLPaintDataHeightExitLoop:
		ENDP
#line 281 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
_paintData__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	pop bc
	pop bc
	pop bc
	ex (sp), hl
	exx
	ret
_putCharsOverMode:
	push ix
	ld ix, 0
	add ix, sp
#line 306 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
		PROC
		LOCAL BLPutChar, BLPutCharColumnLoop, BLPutCharInColumnLoop, BLPutCharSameThird
		LOCAL BLPutCharNextThird, BLPutCharNextColumn, BLPutCharsEnd
		LOCAL op1, op2, op3, op4, op5, op6, op7, op8, opTable, noCarry
		ld      a,(ix+13)
		and     3
		ld      hl, opTable
		add     a, l
		jp      nc, noCarry
		inc     h
noCarry:
		ld      l, a
		ld      a, (hl)
		ld      (op1), a
		ld      (op2), a
		ld      (op3), a
		ld      (op4), a
		ld      (op5), a
		ld      (op6), a
		ld      (op7), a
		ld      (op8), a
		jp      BLPutChar
opTable:
		DEFB $00
		DEFB $AE
		DEFB $A6
		DEFB $B6
BLPutChar:
		ld      a,(ix+5)
		ld      l,a
		ld      a,(ix+7)
		ld      d,a
		and     24
		ld      h,a
		ld      a,d
		and     7
		rrca
		rrca
		rrca
		or      l
		ld      l,a
		push hl
		ld e,(ix+14)
		ld d,(ix+15)
		ld b,(ix+9)
		push bc
BLPutCharColumnLoop:
		ld b, (ix+11)
BLPutCharInColumnLoop:
		push hl
		push de
		ld de, (.core.SCREEN_ADDR)
		add hl, de
		pop de
		ld a,(de)
op1:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op2:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op3:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op4:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op5:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op6:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op7:
		nop
		ld (hl),a
		inc de
		inc h
		ld a,(de)
op8:
		nop
		ld (hl),a
		pop hl
		inc de
		dec b
		jr z, BLPutCharNextColumn
		push de
		ld   a,l
		and  224
		cp   224
		jr   z,BLPutCharNextThird
BLPutCharSameThird:
		ld   de,32
		add  hl,de
		pop de
		jp BLPutCharInColumnLoop
BLPutCharNextThird:
		ld de,1824
		add hl,de
		pop de
		jp BLPutCharInColumnLoop
BLPutCharNextColumn:
		pop bc
		pop hl
		dec b
		jr z, BLPutCharsEnd
		inc l
		push hl
		push bc
		jp BLPutCharColumnLoop
BLPutCharsEnd:
		ENDP
#line 460 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
_putCharsOverMode__leave:
	exx
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
	;; --- end of user code ---
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
#line 475 "/zxbasic/src/lib/arch/zx48k/stdlib/putchars.bas"
	END
