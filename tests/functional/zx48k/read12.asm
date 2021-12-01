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
_a:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, .DATA.__DATA__1
	call .core.__RESTORE
	ld a, 2
	call .core.__READ
	ld (_a), a
	call .core.__PRINTI8
	call .core.PRINT_EOL
	ld a, 2
	call .core.__READ
	ld (_a), a
	call .core.__PRINTI8
	call .core.PRINT_EOL
.LABEL._test:
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
___DATA__FUNCPTR__0:
	ld hl, .LABEL.__LABEL0
	call .core.__LOADSTR
___DATA__FUNCPTR__0__leave:
	ret
.DATA.__DATA__0:
	DEFB 81h
	DEFW ___DATA__FUNCPTR__0
.DATA.__DATA__1:
	DEFB 3
	DEFB 1
	DEFB 3
	DEFB 2
__DATA__END:
	DEFB 00h
.LABEL.__LABEL0:
	DEFW 0004h
	DEFB 68h
	DEFB 6Fh
	DEFB 6Ch
	DEFB 61h
	;; --- end of user code ---
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
#line 69 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
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
#line 70 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
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
#line 51 "zx48k/read12.bas"
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
#line 52 "zx48k/read12.bas"
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
#line 53 "zx48k/read12.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
	;; This implements READ & RESTORE functions
	;; Reads a new element from the DATA Address code
	;; Updates the DATA_ADDR read ptr for the next read
	;; Data codification is 1 byte for type followed by data bytes
	;; Byte type is encoded as follows
;; 00: End of data
;; 01: String
;; 02: Byte
;; 03: Ubyte
;; 04: Integer
;; 05: UInteger
;; 06: Long
;; 07: ULong
;; 08: Fixed
;; 09: Float
	;; bit7 is set for a parameter-less function
	;; In that case, the next two bytes are the ptr of the function to jump
#line 1 "/zxbasic/src/arch/zx48k/library-asm/iload32.asm"
	; __FASTCALL__ routine which
	; loads a 32 bits integer into DE,HL
	; stored at position pointed by POINTER HL
	; DE,HL <-- (HL)
	    push namespace core
__ILOAD32:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	    ex de, hl
	    ret
	    pop namespace
#line 25 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/iloadf.asm"
	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- ((HL))
	    push namespace core
__ILOADF:
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a
	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- (HL)
__LOADF:    ; Loads a 40 bits FP number from address pointed by HL
	    ld a, (hl)
	    inc hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    ret
	    pop namespace
#line 26 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/ftof16reg.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/ftou32reg.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/neg32.asm"
	    push namespace core
__ABS32:
	    bit 7, d
	    ret z
__NEG32: ; Negates DEHL (Two's complement)
	    ld a, l
	    cpl
	    ld l, a
	    ld a, h
	    cpl
	    ld h, a
	    ld a, e
	    cpl
	    ld e, a
	    ld a, d
	    cpl
	    ld d, a
	    inc l
	    ret nz
	    inc h
	    ret nz
	    inc de
	    ret
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/ftou32reg.asm"
	    push namespace core
__FTOU32REG:	; Converts a Float to (un)signed 32 bit integer (NOTE: It's ALWAYS 32 bit signed)
	    ; Input FP number in A EDCB (A exponent, EDCB mantissa)
    ; Output: DEHL 32 bit number (signed)
	    PROC
	    LOCAL __IS_FLOAT
	    LOCAL __NEGATE
	    or a
	    jr nz, __IS_FLOAT
	    ; Here if it is a ZX ROM Integer
	    ld h, c
	    ld l, d
	    ld d, e
	    ret
__IS_FLOAT:  ; Jumps here if it is a true floating point number
	    ld h, e
	    push hl  ; Stores it for later (Contains Sign in H)
	    push de
	    push bc
	    exx
	    pop de   ; Loads mantissa into C'B' E'D'
	    pop bc	 ;
	    set 7, c ; Highest mantissa bit is always 1
	    exx
	    ld hl, 0 ; DEHL = 0
	    ld d, h
	    ld e, l
	    ;ld a, c  ; Get exponent
	    sub 128  ; Exponent -= 128
	    jr z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	    jr c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)
	    ld b, a  ; Loop counter = exponent - 128
__FTOU32REG_LOOP:
	    exx 	 ; Shift C'B' E'D' << 1, output bit stays in Carry
	    sla d
	    rl e
	    rl b
	    rl c
	    exx		 ; Shift DEHL << 1, inserting the carry on the right
	    rl l
	    rl h
	    rl e
	    rl d
	    djnz __FTOU32REG_LOOP
__FTOU32REG_END:
	    pop af   ; Take the sign bit
	    or a	 ; Sets SGN bit to 1 if negative
	    jp m, __NEGATE ; Negates DEHL
	    ret
__NEGATE:
	    exx
	    ld a, d
	    or e
	    or b
	    or c
	    exx
	    jr z, __END
	    inc l
	    jr nz, __END
	    inc h
	    jr nz, __END
	    inc de
	LOCAL __END
__END:
	    jp __NEG32
	    ENDP
__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
	    call __FTOU32REG
	    ld a, l
	    ret
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/ftof16reg.asm"
	    push namespace core
__FTOF16REG:	; Converts a Float to 16.16 (32 bit) fixed point decimal
	    ; Input FP number in A EDCB (A exponent, EDCB mantissa)
	    ld l, a     ; Saves exponent for later
	    or d
	    or e
	    or b
	    or c
	    ld h, e
	    ret z		; Return if ZERO
	    push hl  ; Stores it for later (Contains sign in H, exponent in L)
	    push de
	    push bc
	    exx
	    pop de   ; Loads mantissa into C'B' E'D'
	    pop bc	 ;
	    set 7, c ; Highest mantissa bit is always 1
	    exx
	    ld hl, 0 ; DEHL = 0
	    ld d, h
	    ld e, l
	    pop bc
	    ld a, c  ; Get exponent
	    sub 112  ; Exponent -= 128 + 16
	    push bc  ; Saves sign in b again
	    jp z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	    jp c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)
	    ld b, a  ; Loop counter = exponent - 128 + 16 (we need to shift 16 bit more)
	    jp __FTOU32REG_LOOP ; proceed as an u32 integer
	    pop namespace
#line 27 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/f16tofreg.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/u32tofreg.asm"
	    push namespace core
__I8TOFREG:
	    ld l, a
	    rlca
	    sbc a, a	; A = SGN(A)
	    ld h, a
	    ld e, a
	    ld d, a
__I32TOFREG:	; Converts a 32bit signed integer (stored in DEHL)
	    ; to a Floating Point Number returned in (A ED CB)
	    ld a, d
	    or a		; Test sign
	    jp p, __U32TOFREG	; It was positive, proceed as 32bit unsigned
	    call __NEG32		; Convert it to positive
	    call __U32TOFREG	; Convert it to Floating point
	    set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	    ret
__U8TOFREG:
	    ; Converts an unsigned 8 bit (A) to Floating point
	    ld l, a
	    ld h, 0
	    ld e, h
	    ld d, h
__U32TOFREG:	; Converts an unsigned 32 bit integer (DEHL)
	    ; to a Floating point number returned in A ED CB
	    PROC
	    LOCAL __U32TOFREG_END
	    ld a, d
	    or e
	    or h
	    or l
	    ld b, d
	    ld c, e		; Returns 00 0000 0000 if ZERO
	    ret z
	    push de
	    push hl
	    exx
	    pop de  ; Loads integer into B'C' D'E'
	    pop bc
	    exx
	    ld l, 128	; Exponent
	    ld bc, 0	; DEBC = 0
	    ld d, b
	    ld e, c
__U32TOFREG_LOOP: ; Also an entry point for __F16TOFREG
	    exx
	    ld a, d 	; B'C'D'E' == 0 ?
	    or e
	    or b
	    or c
	    jp z, __U32TOFREG_END	; We are done
	    srl b ; Shift B'C' D'E' >> 1, output bit stays in Carry
	    rr c
	    rr d
	    rr e
	    exx
	    rr e ; Shift EDCB >> 1, inserting the carry on the left
	    rr d
	    rr c
	    rr b
	    inc l	; Increment exponent
	    jp __U32TOFREG_LOOP
__U32TOFREG_END:
	    exx
	    ld a, l     ; Puts the exponent in a
	    res 7, e	; Sets the sign bit to 0 (positive)
	    ret
	    ENDP
	    pop namespace
#line 3 "/zxbasic/src/arch/zx48k/library-asm/f16tofreg.asm"
	    push namespace core
__F16TOFREG:	; Converts a 16.16 signed fixed point (stored in DEHL)
	    ; to a Floating Point Number returned in (C ED CB)
	    PROC
	    LOCAL __F16TOFREG2
	    ld a, d
	    or a		; Test sign
	    jp p, __F16TOFREG2	; It was positive, proceed as 32bit unsigned
	    call __NEG32		; Convert it to positive
	    call __F16TOFREG2	; Convert it to Floating point
	    set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	    ret
__F16TOFREG2:	; Converts an unsigned 32 bit integer (DEHL)
	    ; to a Floating point number returned in C DE HL
	    ld a, d
	    or e
	    or h
	    or l
	    ld b, h
	    ld c, l
	    ret z       ; Return 00 0000 0000 if 0
	    push de
	    push hl
	    exx
	    pop de  ; Loads integer into B'C' D'E'
	    pop bc
	    exx
	    ld l, 112	; Exponent
	    ld bc, 0	; DEBC = 0
	    ld d, b
	    ld e, c
	    jp __U32TOFREG_LOOP ; Proceed as an integer
	    ENDP
	    pop namespace
#line 28 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
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
#line 29 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 31 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 32 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 33 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 34 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 35 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 36 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 37 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 38 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
#line 39 "/zxbasic/src/arch/zx48k/library-asm/read_restore.asm"
	;; Updates restore point to the given HL mem. address
	    push namespace core
__RESTORE:
	    PROC
	    LOCAL __DATA_ADDR
	    ld (__DATA_ADDR), hl
	    ret
	;; Reads a value from the DATA mem area and updates __DATA_ADDR ptr to the
	;; next item. On Out Of Data, restarts
	;;
__READ:
	    LOCAL read_restart, cont, cont2, table, no_func
	    LOCAL dynamic_cast, dynamic_cast2, dynamic_cast3, dynamic_cast4
	    LOCAL _decode_table, coerce_to_int, coerce_to_int2, promote_to_i16
	    LOCAL _from_i8, _from_u8
	    LOCAL _from_i16, _from_u16
	    LOCAL _from_i32, _from_u32
	    LOCAL _from_fixed, __data_error
	    push af  ; type of data to read
	    ld hl, (__DATA_ADDR)
read_restart:
	    ld a, (hl)
	    or a   ; 0 => OUT of data
	    jr nz, cont
	    ;; Signals out of data
	    ld hl, .DATA.__DATA__0
	    ld (__DATA_ADDR), hl
	    jr read_restart  ; Start again
cont:
	    and 0x80
	    ld a, (hl)
	    push af
	    jp z, no_func    ;; Loads data directly, not a function
	    inc hl
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl  ;; Store address of next DATA
	    ex de, hl
cont2:
	    ld de, dynamic_cast
	    push de  ; ret address
	    jp (hl)  ; "call (hl)"
	    ;; Now tries to convert the given result to the expected type or raise an error
dynamic_cast:
	    exx
	    ex af, af'
	    pop af   ; type READ
	    and 0x7F ; clear bit 7
	    pop hl   ; type requested by USER (type of the READ variable)
	    ld c, h  ; save requested type (save it in register C)
	    cp h
	    exx
	    jr nz, dynamic_cast2  ; Types are identical?
	    ;; yes, they are
	    ex af, af'
	    ret
dynamic_cast2:
	    cp 1             ; Requested a number, but read a string?
	    jr nz, dynamic_cast3
	    call __MEM_FREE     ; Frees str from memory
	    jr __data_error
dynamic_cast3:
	    exx
	    ld b, a     ; Read type
	    ld a, c     ; Requested type
	    cp 1
	    jr z, __data_error
	    cp b
	    jr c, dynamic_cast4
	    ;; here the user expected type is "larger" than the read one
	    ld a, b
	    sub 2
	    add a, a
	    ld l, a
	    ld h, 0
	    ld de, _decode_table
	    add hl, de
	    ld e, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, e
	    push hl
	    ld a, c     ; Requested type
	    exx
	    ret
__data_error:
	    ;; When a data is read, but cannot be converted to the requested type
	    ;; that is, the user asked for a string and we read a number or vice versa
	    ld a, ERROR_InvalidArg
	    call __STOP  ; The user expected a string, but read a number
	    xor a
	    ld h, a
	    ld l, a
	    ld e, a
	    ld d, a
	    ld b, a
	    ld c, a
	    ret
_decode_table:
	    dw _from_i8
	    dw _from_u8
	    dw _from_i16
	    dw _from_u16
	    dw _from_i32
	    dw _from_u32
	    dw _from_fixed
_from_i8:
	    cp 4
	    jr nc, promote_to_i16
	    ex af, af'
	    ret     ;; Was from Byte to Ubyte
promote_to_i16:
	    ex af, af'
	    ld l, a
	    rla
	    sbc a, a
	    ld h, a     ; copy sgn to h
	    ex af, af'
	    jr _before_from_i16
_from_u8:
	    ex af, af'
	    ld l, a
	    ld h, 0
	    ex af, af'
	    ;; Promoted to i16
_before_from_i16:
_from_i16:
	    cp 6
	    ret c  ;; from i16 to u16
	    ;; Promote i16 to i32
	    ex af, af'
	    ld a, h
	    rla
	    sbc a, a
	    ld e, a
	    ld d, a
	    ex af, af'
_from_i32:
	    cp 7
	    ret z ;; From i32 to u32
	    ret c ;; From u16 to i32
	    cp 9
	    jp z, __I32TOFREG
_from_u32:
	    cp 9
	    jp z, __U32TOFREG
	    ex de, hl
	    ld hl, 0
	    cp 8
	    ret z
_from_fixed:  ;; From fixed to float
	    jp __F16TOFREG
_from_u16:
	    ld de, 0    ; HL 0x0000 => 32 bits
	    jp _from_i32
dynamic_cast4:
	    ;; The user type is "shorter" than the read one
	    cp 8 ;; required type
	    jr c, before_to_int  ;; required < fixed (f16)
	    ex af, af'
	    exx     ;; Ok, we must convert from float to f16
	    jp __FTOF16REG
before_to_int:
	    ld a, b ;; read type
	    cp 8 ;;
	    jr c, coerce_to_int2
	    jr nz, coerce_to_int  ;; From float to int
	    ld a, c ;; user type
	    exx
	    ;; f16 to Long
	    ex de, hl
	    ld a, h
	    rla
	    sbc a, a
	    ld d, a
	    ld e, a
	    exx
	    jr coerce_to_int2
coerce_to_int:
	    exx
	    ex af, af'
	    call __FTOU32REG
	    ex af, af'   ; a contains user type
	    exx
coerce_to_int2:  ; At this point we have an u/integer in hl
	    exx
	    cp 4
	    ret nc       ; Already done. Return the result
	    ld a, l      ; Truncate to byte
	    ret
no_func:
	    exx
	    ld de, dynamic_cast
	    push de ; Ret address
	    dec a        ; 0 => string; 1, 2 => byte; 3, 4 => integer; 5, 6 => long, 7 => fixed; 8 => float
	    ld h, 0
	    add a, a
	    ld l, a
	    ld de, table
	    add hl, de
	    ld e, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, e
	    push hl ; address to jump to
	    exx
	    inc hl
	    ret     ; jp (sp)  => jump to table[a - 1]
table:
	    LOCAL __01_decode_string
	    LOCAL __02_decode_byte
	    LOCAL __03_decode_ubyte
	    LOCAL __04_decode_integer
	    LOCAL __05_decode_uinteger
	    LOCAL __06_decode_long
	    LOCAL __07_decode_ulong
	    LOCAL __08_decode_fixed
	    LOCAL __09_decode_float
	    ;; 1 -> Decode string
	    ;; 2, 3 -> Decode Byte, UByte
	    ;; 4, 5 -> Decode Integer, UInteger
	    ;; 6, 7 -> Decode Long, ULong
	    ;; 8 -> Decode Fixed
	    ;; 9 -> Decode Float
	    dw __01_decode_string
	    dw __02_decode_byte
	    dw __03_decode_ubyte
	    dw __04_decode_integer
	    dw __05_decode_uinteger
	    dw __06_decode_long
	    dw __07_decode_ulong
	    dw __08_decode_fixed
	    dw __09_decode_float
__01_decode_string:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl  ;; Store address of next DATA
	    ex de, hl
	    jp __LOADSTR
__02_decode_byte:
__03_decode_ubyte:
	    ld a, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl
	    ret
__04_decode_integer:
__05_decode_uinteger:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl
	    ld (__DATA_ADDR), hl
	    ex de, hl
	    ret
__06_decode_long:
__07_decode_ulong:
__08_decode_fixed:
	    ld b, h
	    ld c, l
	    inc bc
	    inc bc
	    inc bc
	    inc bc
	    ld (__DATA_ADDR), bc
	    jp __ILOAD32
__09_decode_float:
	    call __LOADF
	    inc hl
	    ld (__DATA_ADDR), hl
	    ld h, a  ; returns A in H; sets A free
	    ret
__DATA_ADDR:  ;; Stores current DATA ptr
	    dw .DATA.__DATA__0
	    ENDP
	    pop namespace
#line 54 "zx48k/read12.bas"
	END
