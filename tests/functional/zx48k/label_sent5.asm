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
.LABEL._0:
.LABEL._10:
	ld a, 1
	call .core.BORDER
	ld a, 1
	call .core.PAPER
	call .core.COPY_ATTR
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
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/border.asm"
	; __FASTCALL__ Routine to change de border
	; Parameter (color) specified in A register
	    push namespace core
	BORDER EQU 229Bh
	    pop namespace
	; Nothing to do! (Directly from the ZX Spectrum ROM)
#line 24 "zx48k/label_sent5.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
#line 4 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sysvars.asm"
	;; -----------------------------------------------------------------------
	;; ZX Basic System Vars
	;; Some of them will be mapped over Sinclair ROM ones for compatibility
	;; -----------------------------------------------------------------------
	push namespace core
SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)
	; These are mapped onto ZX Spectrum ROM VARS
	CHARS	            EQU 23606  ; Pointer to ROM/RAM Charset
	TVFLAGS             EQU 23612  ; TV Flags
	UDG	                EQU 23675  ; Pointer to UDG Charset
	COORDS              EQU 23677  ; Last PLOT coordinates
	FLAGS2	            EQU 23681  ;
	ECHO_E              EQU 23682  ;
	DFCC                EQU 23684  ; Next screen addr for PRINT
	DFCCL               EQU 23686  ; Next screen attr for PRINT
	S_POSN              EQU 23688
	ATTR_P              EQU 23693  ; Current Permanent ATTRS set with INK, PAPER, etc commands
	ATTR_T	            EQU 23695  ; temporary ATTRIBUTES
	P_FLAG	            EQU 23697  ;
	MEM0                EQU 23698  ; Temporary memory buffer used by ROM chars
	SCR_COLS            EQU 33     ; Screen with in columns + 1
	SCR_ROWS            EQU 24     ; Screen height in rows
	SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS
	pop namespace
#line 6 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
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
#line 65 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
	    ret
#line 67 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
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
#line 25 "zx48k/label_sent5.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/paper.asm"
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
#line 26 "zx48k/label_sent5.bas"
	END
