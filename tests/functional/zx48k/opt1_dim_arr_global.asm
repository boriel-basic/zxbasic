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
	call .core.__PRINT_INIT
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_i:
	DEFB 00, 00
_a:
	DEFW .LABEL.__LABEL0
_a.__DATA__.__PTR__:
	DEFW _a.__DATA__
_a.__DATA__:
	DEFB 00h
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
	DEFB 05h
.LABEL.__LABEL0:
	DEFW 0000h
	DEFB 01h
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, 3
	ld (_i), hl
	push hl
	ld hl, _a
	call .core.__ARRAY
	ld a, (hl)
	call .core.__PRINTU8
	call .core.PRINT_EOL
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/mul16.asm"
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
#line 20 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
#line 24 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    push namespace core
__ARRAY_PTR:   ;; computes an array offset from a pointer
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c
__ARRAY:
	    PROC
	    LOCAL LOOP
	    LOCAL ARRAY_END
	    LOCAL RET_ADDRESS ; Stores return address
	    LOCAL TMP_ARR_PTR ; Stores pointer temporarily
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (TMP_ARR_PTR), hl
	    ex de, hl
	    ex (sp), hl	; Return address in HL, array address in the stack
	    ld (RET_ADDRESS + 1), hl ; Stores it for later
	    exx
	    pop hl		; Will use H'L' as the pointer
	    ld c, (hl)	; Loads Number of dimensions from (hl)
	    inc hl
	    ld b, (hl)
	    inc hl		; Ready
	    exx
	    ld hl, 0	; HL = Offset "accumulator"
LOOP:
#line 64 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    pop bc		; Get next index (Ai) from the stack
#line 74 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    add hl, bc	; Adds current index
	    exx			; Checks if B'C' = 0
	    ld a, b		; Which means we must exit (last element is not multiplied by anything)
	    or c
	    jr z, ARRAY_END		; if B'Ci == 0 we are done
	    ld e, (hl)			; Loads next dimension into D'E'
	    inc hl
	    ld d, (hl)
	    inc hl
	    push de
	    dec bc				; Decrements loop counter
	    exx
	    pop de				; DE = Max bound Number (i-th dimension)
	    call __FNMUL
	    jp LOOP
ARRAY_END:
	    ld a, (hl)
	    exx
#line 103 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    LOCAL ARRAY_SIZE_LOOP
	    ex de, hl
	    ld hl, 0
	    ld b, a
ARRAY_SIZE_LOOP:
	    add hl, de
	    djnz ARRAY_SIZE_LOOP
#line 113 "/zxbasic/src/arch/zx48k/library-asm/array.asm"
	    ex de, hl
	    ld hl, (TMP_ARR_PTR)
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    add hl, de  ; Adds element start
RET_ADDRESS:
	    jp 0
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
TMP_ARR_PTR:
	    DW 0  ; temporary storage for pointer to tables
	    ENDP
	    pop namespace
#line 25 "zx48k/opt1_dim_arr_global.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
; vim:ts=4:sw=4:et:
	; PRINT command routine
	; Does not print attribute. Use PRINT_STR or PRINT_NUM for that
#line 1 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/attr.asm"
	; Attribute routines
; vim:ts=4:et:sw:
#line 1 "/zxbasic/src/arch/zx48k/library-asm/error.asm"
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
#line 6 "/zxbasic/src/arch/zx48k/library-asm/attr.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/in_screen.asm"
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
#line 7 "/zxbasic/src/arch/zx48k/library-asm/attr.asm"
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
#line 3 "/zxbasic/src/arch/zx48k/library-asm/sposn.asm"
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
#line 6 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/table_jump.asm"
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
#line 8 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/ink.asm"
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
#line 9 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 10 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/flash.asm"
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
#line 11 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/bright.asm"
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
#line 12 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/over.asm"
	; Sets OVER flag in P_FLAG permanently
; Parameter: OVER flag in bit 0 of A register
#line 1 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
#line 4 "/zxbasic/src/arch/zx48k/library-asm/copy_attr.asm"
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
#line 4 "/zxbasic/src/arch/zx48k/library-asm/over.asm"
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
#line 13 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/inverse.asm"
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
#line 14 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/bold.asm"
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
#line 15 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/italic.asm"
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
#line 16 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 92 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 139 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
	    bit 4, (iy + $47)
	    call nz, __ITALIC
#line 144 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
	    push hl
	    call __SET_ATTR
	    pop hl
	    inc hl
	    ld (DFCCL),hl
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
#line 210 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
	    exx
	    ld hl, __PRINT_TAB2
	    jr __PRINT_SET_STATE
__PRINT_TAB2:
	    ld a, (MEM0)        ; Load tab code (ignore the current one)
	    push hl
	    push de
	    push bc
	    ld hl, __PRINT_START
	    ld (PRINT_JUMP_STATE), hl
	    call PRINT_TAB
	    pop bc
	    pop de
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
	    ld a, SCR_ROWS
	    sub h
	    ld (S_POSN + 1), a
	    ld hl, __PRINT_AT2
	    jr __PRINT_SET_STATE
__PRINT_AT2:
	    ld hl, __PRINT_START
	    ld (PRINT_JUMP_STATE), hl    ; Saves next entry call
	    ld hl, (S_POSN)
	    ld a, SCR_COLS
	    sub l
	    ld l, a
	    jr __PRINT_EOL_END
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
#line 356 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
__PRINT_ITA:
	    ld hl, __PRINT_ITA2
	    jp __PRINT_SET_STATE
__PRINT_ITA2:
	    call ITALIC_TMP
	    jp __PRINT_RESTART
#line 366 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 387 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 415 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
	    LOCAL __SCROLL_SCR
#line 489 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
	__SCROLL_SCR EQU 0DFEh  ; Use ROM SCROLL
#line 491 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
#line 492 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
PRINT_COMMA:
	    call __LOAD_S_POSN
	    ld a, e
	    and 16
	    add a, 16
PRINT_TAB:
	    PROC
	    LOCAL LOOP
	    call __LOAD_S_POSN ; e = current row
	    sub e
	    and 31
	    ret z
	    ld b, a
LOOP:
	    ld a, ' '
	    push bc
	    exx
	    call __PRINTCHAR
	    exx
	    pop bc
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
#line 550 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
	    LOCAL __PRINT_BOLD2
#line 556 "/zxbasic/src/arch/zx48k/library-asm/print.asm"
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
#line 26 "zx48k/opt1_dim_arr_global.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/printu8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/printi8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/printnum.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/printi8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/div8.asm"
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
#line 3 "/zxbasic/src/arch/zx48k/library-asm/printi8.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/printu8.asm"
#line 27 "zx48k/opt1_dim_arr_global.bas"
	END
