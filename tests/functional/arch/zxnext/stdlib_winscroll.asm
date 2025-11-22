	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
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
	pop iy
	ei
	ret
_WinScrollRight:
#line 27 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleRows, BucleScans, AfterLDDR, AfterLDDR2, AfterLDDR3
		ld b, a
		pop hl
		pop de
		ld a, d
		pop de
		add a, d
		dec a
		ld c, a
		ex (sp), hl
		ld e, h
		ld a, e
		or a
		ret z
		ld a, d
		or a
		ret z
		sub 2
		inc a
		ex af,af'
		push ix
		ld ixL,e
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		add a,c
		ld l,a
		ld de,(SCREEN_ATTR_ADDR)
		add hl,de
BucleRows:
		push bc
		push hl
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		ld b,0
		ex af,af'
		ld ixH,7
BucleScans:
		push hl
		jr c,AfterLDDR
		ld d,h
		ld e,l
		dec hl
		ld c,a
		lddr
		ex de,hl
AfterLDDR:
		ld (hl),b
		pop hl
		inc h
		dec ixH
		jp nz,BucleScans
		jr c,AfterLDDR2
		ld d,h
		ld e,l
		dec hl
		ld c,a
		lddr
		ex de,hl
AfterLDDR2:
		ld (hl),b
		pop hl
		jr c,AfterLDDR3
		ld d,h
		ld e,l
		dec hl
		ld c,a
		push de
		lddr
		pop hl
AfterLDDR3:
		ex af,af'
		ld de,32
		add hl,de
		pop bc
		inc b
		dec ixL
		jp nz,BucleRows
		pop ix
		ENDP
		pop namespace
#line 139 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
_WinScrollRight__leave:
	ret
_WinScrollLeft:
#line 149 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleRows, BucleScans, AfterLDIR, AfterLDIR2, AfterLDIR3
		ld b, a
		pop hl
		pop de
		ld c, d
		pop de
		ex (sp), hl
		ld e, h
		ld a, e
		or a
		ret z
		ld a, d
		or a
		ret z
		sub 2
		inc a
		ex af,af'
		push ix
		ld ixL,e
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		add a,c
		ld l,a
		ld de,(SCREEN_ATTR_ADDR)
		add hl,de
BucleRows:
		push bc
		push hl
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		ld b,0
		ex af,af'
		ld ixH,7
BucleScans:
		push hl
		jr c,AfterLDIR
		ld d,h
		ld e,l
		inc hl
		ld c,a
		ldir
		ex de,hl
AfterLDIR:
		ld (hl),b
		pop hl
		inc h
		dec ixH
		jp nz,BucleScans
		jr c,AfterLDIR2
		ld d,h
		ld e,l
		inc hl
		ld c,a
		ldir
		ex de,hl
AfterLDIR2:
		ld (hl),b
		pop hl
		jr c,AfterLDIR3
		ld d,h
		ld e,l
		inc hl
		ld c,a
		push de
		ldir
		pop hl
AfterLDIR3:
		ex af,af'
		ld de,32
		add hl,de
		pop bc
		inc b
		dec ixL
		jp nz,BucleRows
		pop ix
		ENDP
		pop namespace
#line 258 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
_WinScrollLeft__leave:
	ret
_WinScrollUp:
#line 268 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleRows, BucleScans, AttrAddress
		LOCAL CleanBottomRow, CleanBottomScans, AfterLDIR
		ld b, a
		pop hl
		pop de
		ld c, d
		pop de
		ex (sp), hl
		ld e, h
		ld a, e
		or a
		ret z
		ld a, d
		or a
		ret z
		ex af,af'
		push ix
		ld ixL,e
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		add a,c
		ld l,a
		ld de,(SCREEN_ATTR_ADDR)
		add hl,de
		ld (AttrAddress+1),hl
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		push hl
BucleRows:
		dec ixL
		jr z,CleanBottomRow
		inc b
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		pop de
		push hl
		push bc
		ld b,0
		ex af,af'
		ld ixH,7
BucleScans:
		ld c,a
		push de
		push hl
		ldir
		pop hl
		pop de
		inc h
		inc d
		dec ixH
		jp nz,BucleScans
		ld c,a
		ldir
AttrAddress:
		ld hl,AttrAddress
		ld d,h
		ld e,l
		ld c,32
		add hl,bc
		ld (AttrAddress+1),hl
		ld c,a
		ldir
		ex af,af'
		pop bc
		jp BucleRows
CleanBottomRow:
		ld b,0
		ex af,af'
		ld ixH,8
		pop hl
CleanBottomScans:
		ld (hl),b
		ld c,a
		dec c
		jr z,AfterLDIR
		push hl
		ld d,h
		ld e,l
		inc de
		ldir
		pop hl
AfterLDIR:
		inc h
		dec ixH
		jp nz,CleanBottomScans
		pop ix
		ENDP
		pop namespace
#line 402 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
_WinScrollUp__leave:
	ret
_WinScrollDown:
#line 412 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleRows, BucleScans, AttrAddress
		LOCAL CleanTopRow, CleanTopScans, AfterLDIR
		ld b, a
		pop hl
		pop de
		ld c, d
		pop de
		ex (sp), hl
		ld e, h
		ld a, b
		add a, e
		dec a
		ld b, a
		ld a, e
		or a
		ret z
		ld a, d
		or a
		ret z
		ex af,af'
		push ix
		ld ixL,e
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		add a,c
		ld l,a
		ld de,(SCREEN_ATTR_ADDR)
		add hl,de
		ld (AttrAddress+1),hl
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		push hl
BucleRows:
		dec ixL
		jr z,CleanTopRow
		dec b
		ld a,b
		and %00011000
		ld h,a
		ld a,b
		and %00000111
		rrca
		rrca
		rrca
		add a,c
		ld l,a
		ld de,(SCREEN_ADDR)
		add hl,de
		pop de
		push hl
		push bc
		ld b,0
		ex af,af'
		ld ixH,7
BucleScans:
		ld c,a
		push de
		push hl
		ldir
		pop hl
		pop de
		inc h
		inc d
		dec ixH
		jp nz,BucleScans
		ld c,a
		ldir
AttrAddress:
		ld hl,AttrAddress
		ld d,h
		ld e,l
		ld c,32
		sbc hl,bc
		ld (AttrAddress+1),hl
		ld c,a
		ldir
		ex af,af'
		pop bc
		jp BucleRows
CleanTopRow:
		ld b,0
		ex af,af'
		ld ixH,8
		pop hl
CleanTopScans:
		ld (hl),b
		ld c,a
		dec c
		jr z,AfterLDIR
		push hl
		ld d,h
		ld e,l
		inc de
		ldir
		pop hl
AfterLDIR:
		inc h
		dec ixH
		jp nz,CleanTopScans
		pop ix
		ENDP
		pop namespace
#line 550 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
_WinScrollDown__leave:
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/sysvars.asm"
	;; -----------------------------------------------------------------------
	;; ZX Basic System Vars
	;; Some of them will be mapped over Sinclair ROM ones for compatibility
	;; -----------------------------------------------------------------------
	push namespace core
SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)
	; These are mapped onto ZX Spectrum ROM VARS
	CHARS               EQU 23606  ; Pointer to ROM/RAM Charset
	TV_FLAG             EQU 23612  ; TV Flags
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
#line 555 "/zxbasic/src/lib/arch/zxnext/stdlib/winscroll.bas"
	END
