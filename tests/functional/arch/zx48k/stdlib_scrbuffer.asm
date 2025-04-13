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
_GetScreenBufferAddr:
#line 26 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
		ld hl, (.core.SCREEN_ADDR)
#line 29 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
_GetScreenBufferAddr__leave:
	ret
_SetScreenBufferAddr:
#line 44 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
		ld (.core.SCREEN_ADDR), hl
#line 47 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
_SetScreenBufferAddr__leave:
	ret
_GetAttrBufferAddr:
#line 57 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
		ld hl, (.core.SCREEN_ATTR_ADDR)
#line 60 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
_GetAttrBufferAddr__leave:
	ret
_SetAttrBufferAddr:
#line 75 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
		ld (.core.SCREEN_ATTR_ADDR), hl
#line 78 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
_SetAttrBufferAddr__leave:
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
#line 83 "/zxbasic/src/lib/arch/zx48k/stdlib/scrbuffer.bas"
	END
