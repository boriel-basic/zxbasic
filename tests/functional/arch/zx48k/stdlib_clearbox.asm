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
_clearBox:
	push ix
	ld ix, 0
	add ix, sp
#line 37 "/zxbasic/src/lib/arch/zx48k/stdlib/clearbox.bas"
		PROC
		LOCAL clearbox_outer_loop, clearbox_mid_loop
		LOCAL clearbox_inner_loop, clearbox_row_skip
		ld b,(IX+5)
		ld c,(IX+7)
		ld a, c
		and 24
		ld h, a
		ld a, c
		and 7
		rra
		rra
		rra
		rra
		add a, b
		ld l, a
		ld b, (IX+11)
		ld c,(IX+9)
clearbox_outer_loop:
		xor a
		push bc
		push hl
		ld de, (.core.SCREEN_ADDR)
		add hl, de
		ld d, 8
clearbox_mid_loop:
		push hl
		ld b,c
clearbox_inner_loop:
		ld (hl), a
		inc hl
		djnz clearbox_inner_loop
		pop hl
		inc h
		dec d
		jp nz, clearbox_mid_loop
		pop hl
		pop bc
		ld a, 32
		add a, l
		ld l, a
		jr nc, clearbox_row_skip
		ld a, 8
		add a, h
		ld h, a
clearbox_row_skip:
		djnz clearbox_outer_loop
		ENDP
#line 101 "/zxbasic/src/lib/arch/zx48k/stdlib/clearbox.bas"
_clearBox__leave:
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
#line 115 "/zxbasic/src/lib/arch/zx48k/stdlib/clearbox.bas"
	END
