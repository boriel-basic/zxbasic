	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	call __MEM_INIT
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
ZXBASIC_HEAP_SIZE EQU 4768
ZXBASIC_MEM_HEAP:
	DEFS 4768
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld hl, __LABEL0
	call __LOADSTR
	push hl
	ld hl, 16384
	push hl
	ld hl, 6912
	push hl
	call SAVE_CODE
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__LABEL0:
	DEFW 0004h
	DEFB 74h
	DEFB 65h
	DEFB 73h
	DEFB 74h
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
#line 111 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
	        ret z ; NULL
#line 113 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
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
#line 2 "/zxbasic/src/arch/zx48k/library-asm/loadstr.asm"
	; Loads a string (ptr) from HL
	; and duplicates it on dynamic memory again
	; Finally, it returns result pointer in HL
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
#line 31 "save.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/save.asm"
	; Save code "XXX" at address YYY of length ZZZ
	; Parameters in the stack are XXX (16 bit) address of string name
	; (only first 12 chars will be taken into account)
	; YYY and ZZZ are 16 bit on top of the stack.
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
#line 8 "/zxbasic/src/arch/zx48k/library-asm/save.asm"
SAVE_CODE:
	    PROC
	    LOCAL MEMBOT
	    LOCAL SAVE_CONT
	    LOCAL ROM_SAVE
	    LOCAL __ERR_EMPTY
	    LOCAL SAVE_STOP
	    LOCAL STR_PTR
	    LOCAL SAVE_EMPTY_ERROR
#line 24 "/zxbasic/src/arch/zx48k/library-asm/save.asm"
	    MEMBOT EQU 23698 ; Use the CALC mem to store header
	    STR_PTR EQU MEMBOT + 17
	    pop hl   ; Return address
	    pop bc     ; data length in bytes
	    pop de   ; address start
	    ex (sp), hl ; CALLE => now hl = String
	    ld (STR_PTR), hl
	; This function will call the ROM SAVE CODE Routine
	; Parameters in the stack are HL => String with SAVE name
	; (only first 12 chars will be taken into account)
	; DE = START address of CODE to save
	; BC = Length of data in bytes
__SAVE_CODE: ; INLINE version
	    ld a, b
	    or c
	    jr z, SAVE_EMPTY_ERROR    ; Return if block length == 0
	    push ix
	    ld a, h
	    or l
	    jr z, __ERR_EMPTY  ; Return if NULL STRING
	    ld ix, MEMBOT
	    ld (ix + 00), 3 ; CODE
	    ld (ix + 11), c
	    ld (ix + 12), b ; Store long in bytes
	    ld (ix + 13), e
	    ld (ix + 14), d ; Store address in bytes
	    push hl
	    ld bc, 9
	    ld HL, MEMBOT + 1
	    ld DE, MEMBOT + 2
	    ld (hl), ' '
	    ldir   ; Fill the filename with blanks
	    pop hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc hl
	    ld a, b
	    or c
__ERR_EMPTY:
	    ld a, ERROR_InvalidFileName
	    jr z, SAVE_STOP        ; Return if str len == 0
	    ex de, hl  ; Saves HL in DE
	    ld hl, 10
	    or a
	    sbc hl, bc  ; Test BC > 10?
	    ex de, hl
	    jr nc, SAVE_CONT ; Ok BC <= 10
	    ld bc, 10 ; BC at most 10 chars
SAVE_CONT:
	    ld de, MEMBOT + 1
	    ldir     ; Copy String block NAME
	    ld hl, (STR_PTR)
	    call MEM_FREE
	    ld l, (ix + 13)
	    ld h, (ix + 14)    ; Restores start of bytes
	    ld a, r
	    push af
	    call ROM_SAVE
	    LOCAL NO_INT
	    pop af
	    jp po, NO_INT
	    ei
NO_INT:
	    ; Recovers ECHO_E since ROM SAVE changes it
	    ld hl, 1821h
	    ld (23682), hl
	    pop ix
	    ret
SAVE_EMPTY_ERROR:
	    ld a, ERROR_InvalidArg
SAVE_STOP:
	    pop ix
	    push af
	    ld hl, (STR_PTR)
	    call MEM_FREE
	    pop af
	    jp __STOP
	    LOCAL CHAN_OPEN
	    LOCAL PO_MSG
	    LOCAL WAIT_KEY
	    LOCAL SA_BYTES
	    LOCAL SA_CHK_BRK
	    LOCAL SA_CONT
	    CHAN_OPEN EQU 1601h
	    PO_MSG EQU 0C0Ah
	    WAIT_KEY EQU 15D4h
	    SA_BYTES EQU 04C6h
ROM_SAVE:
	    push hl
	    ld a, 0FDh
	    call CHAN_OPEN
	    xor a
	    ld de, 09A1h
	    call PO_MSG
	    set 5, (iy + 02h)
	    call WAIT_KEY
	    push ix
	    ld de, 0011h
	    xor a
	    call SA_BYTES
	    pop ix
	    call SA_CHK_BRK
	    jr c, SA_CONT
	    pop ix
	    ret
SA_CONT:
	    ei
	    ld b, 32h
	LOCAL SA_1_SEC
SA_1_SEC:
	    halt
	    djnz SA_1_SEC
	    ld e, (ix + 0Bh)
	    ld d, (ix + 0Ch)
	    ld a, 0FFh
	    pop ix
	    call SA_BYTES
SA_CHK_BRK:
	    ld b, a
	    ld a, (5C48h)
	    and 38h
	    rrca
	    rrca
	    rrca
	    out (0FEh), a
	    ld a, 7Fh
	    in a, (0FEh)
	    rra
	    ld a, b
	    ret
#line 181 "/zxbasic/src/arch/zx48k/library-asm/save.asm"
	    ENDP
#line 32 "save.bas"
	END
