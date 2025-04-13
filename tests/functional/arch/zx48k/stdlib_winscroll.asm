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
_WinScrollRight:
#line 24 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
		push namespace core
		LOCAL BucleChars
		LOCAL BucleScans
		LOCAL BucleAttrs
		PROC
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
		or d
		ret z
		push bc
		ld a,b
		and 18h
		ld h,a
		ld a,b
		and 07h
		add a,a
		add a,a
		add a,a
		add a,a
		add a,a
		add a,c
		add a,d
		dec a
		ld l,a
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld b,e
BucleChars:
		push bc
		ld b,8
BucleScans:
		push bc
		push de
		push hl
		ld c,d
		dec c
		ld b,0
		ld d,h
		ld e,l
		dec l
		lddr
		xor a
		ld (de),a
		pop hl
		pop de
		inc h
		pop bc
		djnz BucleScans
		dec h
		call SP.PixelDown
		pop bc
		djnz BucleChars
		pop bc
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		add a,c
		add a,d
		dec a
		ld l,a
		ld a,h
		ld h,a
		ld bc, (SCREEN_ATTR_ADDR)
		add hl, bc
		ld b,e
BucleAttrs:
		push bc
		push de
		push hl
		ld c,d
		dec c
		ld b,0
		ld d,h
		ld e,l
		dec l
		lddr
		pop hl
		ld de,32
		add hl,de
		pop de
		pop bc
		djnz BucleAttrs
		ENDP
		pop namespace
#line 130 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
_WinScrollRight__leave:
	ret
_WinScrollLeft:
#line 138 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleChars
		LOCAL BucleScans
		LOCAL BucleAttrs
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
		or d
		ret z
		push bc
		ld a,b
		and 18h
		ld h,a
		ld a,b
		and 07h
		add a,a
		add a,a
		add a,a
		add a,a
		add a,a
		add a,c
		ld l,a
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld b,e
BucleChars:
		push bc
		ld b,8
BucleScans:
		push bc
		push de
		push hl
		ld c,d
		dec c
		ld b,0
		ld d,h
		ld e,l
		inc e
		ex de,hl
		ldir
		xor a
		ld (de),a
		pop hl
		pop de
		inc h
		pop bc
		djnz BucleScans
		dec h
		call SP.PixelDown
		pop bc
		djnz BucleChars
		pop bc
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
		ld a,h
		ld h,a
		ld bc, (SCREEN_ATTR_ADDR)
		add hl, bc
		ld b,e
BucleAttrs:
		push bc
		push de
		push hl
		ld c,d
		dec c
		ld b,0
		ld d,h
		ld e,l
		inc e
		ex de,hl
		ldir
		pop hl
		ld de,32
		add hl,de
		pop de
		pop bc
		djnz BucleAttrs
		ENDP
		pop namespace
#line 241 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
_WinScrollLeft__leave:
	ret
_WinScrollUp:
#line 249 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleScans, BucleAttrs, ScrollAttrs
		LOCAL CleanLast, CleanLastLoop, EndCleanScan
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
		or d
		ret z
		push bc
		push de
		ld a,b
		and 18h
		ld h,a
		ld a,b
		and 07h
		add a,a
		add a,a
		add a,a
		add a,a
		add a,a
		add a,c
		ld l,a
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld a,e
		ld c, d
		ld d, h
		ld e, l
		dec a
		jr z, CleanLast
		add a,a
		add a,a
		add a,a
		ld b, a
		inc h
		inc h
		inc h
		inc h
		inc h
		inc h
		inc h
		call SP.PixelDown
BucleScans:
		push bc
		push de
		push hl
		ld b, 0
		ldir
		pop hl
		pop de
		pop bc
		call SP.PixelDown
		ex de, hl
		call SP.PixelDown
		ex de, hl
		djnz BucleScans
CleanLast:
		ex de,hl
		pop de
		ld b, 8
		ld c, d
		push de
CleanLastLoop:
		push bc
		push hl
		ld (hl), 0
		dec c
		jr z, EndCleanScan
		ld d, h
		ld e, l
		inc de
		ld b, 0
		ldir
EndCleanScan:
		pop hl
		pop bc
		inc h
		djnz CleanLastLoop
ScrollAttrs:
		pop de
		pop bc
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
		ld a,h
		ld h,a
		ld bc, (SCREEN_ATTR_ADDR)
		add hl, bc
		ld b,e
		dec b
		ret z
BucleAttrs:
		push bc
		push de
		push hl
		ld b,0
		ld c,d
		ex de,hl
		ld hl,32
		add hl,de
		ldir
		pop hl
		ld de,32
		add hl,de
		pop de
		pop bc
		djnz BucleAttrs
		ENDP
		pop namespace
#line 385 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
_WinScrollUp__leave:
	ret
_WinScrollDown:
#line 394 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
		push namespace core
		PROC
		LOCAL BucleScans, BucleAttrs, ScrollAttrs
		LOCAL CleanLast, CleanLastLoop, EndCleanScan
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
		or d
		ret z
		ld a, b
		add a, e
		dec a
		ld b, a
		push bc
		push de
		ld a,b
		and 18h
		ld h,a
		ld a,b
		and 07h
		add a,a
		add a,a
		add a,a
		add a,a
		add a,a
		add a,c
		ld l,a
		ld bc, (SCREEN_ADDR)
		add hl, bc
		ld a,e
		ld c, d
		ld d, h
		ld e, l
		dec a
		jr z, CleanLast
		add a,a
		add a,a
		add a,a
		ld b, a
		inc d
		inc d
		inc d
		inc d
		inc d
		inc d
		inc d
		call SP.PixelUp
BucleScans:
		push bc
		push de
		push hl
		ld b, 0
		ldir
		pop hl
		pop de
		pop bc
		call SP.PixelUp
		ex de, hl
		call SP.PixelUp
		ex de, hl
		djnz BucleScans
CleanLast:
		ex de,hl
		pop de
		ld b, 8
		ld c, d
		push de
CleanLastLoop:
		push bc
		push hl
		ld (hl), 0
		dec c
		jr z, EndCleanScan
		ld d, h
		ld e, l
		inc de
		ld b, 0
		ldir
EndCleanScan:
		pop hl
		pop bc
		dec h
		djnz CleanLastLoop
ScrollAttrs:
		pop de
		pop bc
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
		ld a,h
		ld h,a
		ld bc, (SCREEN_ATTR_ADDR)
		add hl, bc
		ld b,e
		dec b
		ret z
BucleAttrs:
		push bc
		push de
		push hl
		ld b,0
		ld c,d
		ex de,hl
		ld hl,-32
		add hl,de
		ldir
		pop hl
		ld de,-32
		add hl,de
		pop de
		pop bc
		djnz BucleAttrs
		ENDP
		pop namespace
#line 535 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
_WinScrollDown__leave:
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
#line 540 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
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
#line 541 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
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
#line 542 "/zxbasic/src/lib/arch/zx48k/stdlib/winscroll.bas"
	END
