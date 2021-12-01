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
_variableToSave:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, .LABEL.__LABEL0
	call .core.__LOADSTR
	push hl
	ld hl, _variableToSave
	push hl
	ld hl, 2
	push hl
	ld a, 1
	push af
	call .core.LOAD_CODE
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
.LABEL.__LABEL0:
	DEFW 0005h
	DEFB 74h
	DEFB 65h
	DEFB 73h
	DEFB 74h
	DEFB 31h
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/free.asm"
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/heapinit.asm"
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
#line 69 "/zxbasic/src/arch/zx48k/library-asm/free.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
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
#line 5 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
#line 6 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    push namespace core
LOAD_CODE:
	; This function will implement the LOAD CODE Routine
	; Parameters in the stack are HL => String with LOAD name
	; (only first 12 chars will be taken into account)
	; DE = START address of CODE to save
	; BC = Length of data in bytes
	; A = 1 => LOAD 0 => Verify
	    PROC
	    LOCAL LOAD_CONT, LOAD_CONT2, LOAD_CONT3
	    LOCAL LD_BYTES
	    LOCAL LOAD_HEADER
	    LOCAL LD_LOOK_H
	    LOCAL HEAD1
	    LOCAL TMP_HEADER
	    LOCAL LD_NAME
	    LOCAL LD_CH_PR
	    LOCAL LOAD_END
	    LOCAL VR_CONTROL, VR_CONT_1, VR_CONT_2
	    LOCAL MEM0
	    LOCAL TMP_SP
	MEM0  EQU 5C92h ; Temporary memory buffer
	HEAD1 EQU MEM0 + 8 ; Uses CALC Mem for temporary storage
	    ; Must skip first 8 bytes used by
	    ; PRINT routine
	TMP_HEADER EQU HEAD1 + 17 ; Temporary HEADER2 pointer storage
	TMP_SP EQU TMP_HEADER + 2 ; Temporary SP storage
#line 42 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	TMP_FLAG EQU 23655 ; Uses BREG as a Temporary FLAG
	    pop hl         ; Return address
	    pop af         ; A = 1 => LOAD; A = 0 => VERIFY
	    pop bc         ; data length in bytes
	    pop de         ; address start
	    ex (sp), hl    ; CALLE => now hl = String
__LOAD_CODE: ; INLINE version
	    push ix ; saves IX
	    ld (TMP_FLAG), a ; Stores verify/load flag
	    ; Prepares temporary 1st header descriptor
	    ld ix, HEAD1
	    ld (ix + 0), 3     ; ZXBASIC ALWAYS uses CODE
	    ld (ix + 1), 0FFh  ; Wildcard for empty string
	    ld (ix + 11), c
	    ld (ix + 12), b ; Store length in bytes
	    ld (ix + 13), e
	    ld (ix + 14), d ; Store address in bytes
	    push hl  ; String ptr to be freed later
	    ld a, h
	    or l
	    ld b, h
	    ld c, l
	    jr z, LOAD_HEADER ; NULL STRING => LOAD ""
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    ld a, b
	    or c
	    jr z, LOAD_CONT2 ; NULL STRING => LOAD ""
	    ; Fill with blanks
	    push hl
	    push bc
	    ld hl, HEAD1 + 2
	    ld de, HEAD1 + 3
	    ld bc, 8
	    ld (hl), ' '
	    ldir
	    pop bc
	    pop hl
LOAD_HEADER:
	    ex de, hl  ; Saves HL in DE
	    ld hl, 10
	    or a
	    sbc hl, bc ; Test BC > 10?
	    ex de, hl  ; Retrieve HL
	    jr nc, LOAD_CONT ; Ok BC <= 10
	    ld bc, 10 ; BC at most 10 chars
LOAD_CONT:
	    ld de, HEAD1 + 1
	    ldir     ; Copy String block NAME in header
LOAD_CONT2:
	    pop hl   ; String ptr
	    call MEM_FREE
	    ld hl, 0
	    add hl, sp
	    ld (TMP_SP), hl
	    ld bc, -18
	    add hl, bc
	    ld sp, hl
LOAD_CONT3:
	    ld (TMP_HEADER), hl
	    push hl
	    pop ix
	;; LD-LOOK-H --- RIPPED FROM ROM at 0x767
LD_LOOK_H:
	    push ix                 ; save IX
	    ld de, 17               ; seventeen bytes
	    xor a                   ; reset zero flag
	    scf                     ; set carry flag
	    call LD_BYTES           ; routine LD-BYTES loads a header from tape
	    ; to second descriptor.
	    pop ix                  ; restore IX
	    jr nc, LD_LOOK_H        ; loop back to LD-LOOK-H until header found.
	    ld c, 80h               ; C has bit 7 set to indicate header type mismatch as
	    ; a default startpoint.
	    ld a, (ix + 0)          ; compare loaded type
	    cp 3		            ; with expected bytes header
	    jr nz, LD_TYPE          ; forward to LD-TYPE with mis-match.
	    ld c, -10               ; set C to minus ten - will count characters
	    ; up to zero.
LD_TYPE:
	    cp 4                    ; check if type in acceptable range 0 - 3.
	    jr nc, LD_LOOK_H        ; back to LD-LOOK-H with 4 and over.
	    ; else A indicates type 0-3.
	    call PRINT_TAPE_MESSAGES; Print tape msg
#line 150 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    ld hl, HEAD1 + 1        ; point HL to 1st descriptor.
	    ld de, (TMP_HEADER)     ; point DE to 2nd descriptor.
	    ld b, 10                ; the count will be ten characters for the
	    ; filename.
	    ld a, (hl)              ; fetch first character and test for
	    inc a                   ; value 255.
	    jr nz, LD_NAME          ; forward to LD-NAME if not the wildcard.
	;   but if it is the wildcard, then add ten to C which is minus ten for a type
	;   match or -128 for a type mismatch. Although characters have to be counted
	;   bit 7 of C will not alter from state set here.
	    ld a, c                 ; transfer $F6 or $80 to A
	    add a, b                ; add 10
	    ld c, a                 ; place result, zero or -118, in C.
	;   At this point we have either a type mismatch, a wildcard match or ten
	;   characters to be counted. The characters must be shown on the screen.
	;; LD-NAME
LD_NAME:
	    inc de                  ; address next input character
	    ld a, (de)              ; fetch character
	    cp (hl)                 ; compare to expected
	    inc hl                  ; address next expected character
	    jr nz, LD_CH_PR         ; forward to LD-CH-PR with mismatch
	    inc c                   ; increment matched character count
	;; LD-CH-PR
LD_CH_PR:
	    call __PRINTCHAR        ; PRINT-A prints character
#line 186 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    djnz LD_NAME            ; loop back to LD-NAME for ten characters.
	    bit 7, c                ; test if all matched
	    jr nz, LD_LOOK_H        ; back to LD-LOOK-H if not
	;   else print a terminal carriage return.
	    ld a, 0Dh               ; prepare carriage return.
	    call __PRINTCHAR        ; PRINT-A outputs it.
#line 197 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    ld a, (HEAD1)
    cp 03                   ; Only "bytes:" header is used un ZX BASIC
	    jr nz, LD_LOOK_H
	    ; Ok, ready to check for bytes start and end
VR_CONTROL:
	    ld e, (ix + 11)         ; fetch length of new data
	    ld d, (ix + 12)         ; to DE.
	    ld hl, HEAD1 + 11
	    ld a, (hl)              ; fetch length of old data (orig. header)
	    inc hl
	    ld h, (hl)              ; to HL
	    ld l, a
	    or h                    ; check length of old for zero. (Carry reset)
	    jr z, VR_CONT_1         ; forward to VR-CONT-1 if length unspecified
	    ; e.g. LOAD "x" CODE
	    sbc hl, de
	    jr nz, LOAD_ERROR       ; Lengths don't match
VR_CONT_1:
	    ld hl, HEAD1 + 13       ; fetch start of old data (orig. header)
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    or h                    ; check start for zero (unspecified)
	    jr nz, VR_CONT_2        ; Jump if there was a start
	    ld l, (ix + 13)         ; otherwise use destination in header
	    ld h, (ix + 14)         ; and load code at addr. saved from
VR_CONT_2:
	    push hl
	    pop ix                  ; Transfer load addr to IX
	    ld a, (TMP_FLAG)        ; load verify/load flag
	    sra a                   ; shift bit 0 to Carry (1 => Load, 0 = Verify), A = 0
	    dec a                   ; a = 0xFF (Data)
	    call LD_BYTES
	    jr c, LOAD_END         ; if carry, load/verification was ok
LOAD_ERROR:
	    ; Sets ERR_NR with Tape Loading, and returns
	    ld a, ERROR_TapeLoadingErr
	    ld (ERR_NR), a
LOAD_END:
	    ld hl, (TMP_SP)
	    ld sp, hl               ; Recovers stack
	    pop ix                  ; Recovers stack frame pointer
	    ret
	    LOCAL LD_BYTES_RET
	    LOCAL LD_BYTES_ROM
	    LOCAL LD_BYTES_NOINTER
	LD_BYTES_ROM EQU 0562h
LD_BYTES:
	    inc d
	    ex af, af'
	    dec d
	    ld a, r
	    push af
	    di
	    call 0562h
LD_BYTES_RET:
	    ; Restores DI / EI state
	    ex af, af'
	    pop af
	    jp po, LD_BYTES_NOINTER
	    ei
LD_BYTES_NOINTER:
	    ex af, af'
	    ret
#line 280 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    ENDP
PRINT_TAPE_MESSAGES:
	    PROC
	    LOCAL LOOK_NEXT_TAPE_MSG
	    LOCAL PRINT_TAPE_MSG
	    ; Print tape messages according to A value
	    ; Each message starts with a carriage return and
	    ; ends with last char having its bit 7 set
    ; A = 0 => '\nProgram: '
    ; A = 1 => '\nNumber array: '
    ; A = 2 => '\nCharacter array: '
    ; A = 3 => '\nBytes: '
	    push bc
	    ld hl, 09C0h            ; address base of last 4 tape messages
	    ld b, a
	    inc b                   ; avoid 256-loop if b == 0
	    ld a, 0Dh               ; Msg start mark
	    ; skip memory bytes looking for next tape msg entry
	    ; each msg ends when 0Dh is fond
LOOK_NEXT_TAPE_MSG:
	    inc hl                  ; Point to next char
	    cp (hl)                 ; Is it 0Dh?
	    jr nz, LOOK_NEXT_TAPE_MSG
	    ; Ok next message found
	    djnz LOOK_NEXT_TAPE_MSG ; Repeat if more msg to skip
PRINT_TAPE_MSG:
	    ; Ok. This will print bytes after (HL)
	    ; until one of them has bit 7 set
	    ld a, (hl)
	    and 7Fh		    ; Clear bit 7 of A
	    call __PRINTCHAR
	    ld a, (hl)
	    inc hl
	    add a, a                ; Carry if A >= 128
	    jr nc, PRINT_TAPE_MSG
	    pop bc
	    ret
	    ENDP
#line 334 "/zxbasic/src/arch/zx48k/library-asm/load.asm"
	    pop namespace
#line 34 "zx48k/load02.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/loadstr.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
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
#line 113 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
	    ret z ; NULL
#line 115 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/loadstr.asm"
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
#line 35 "zx48k/load02.bas"
	END
