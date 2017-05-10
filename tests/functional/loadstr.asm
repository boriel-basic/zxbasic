	org 32768
	; Defines HEAP SIZE
ZXBASIC_HEAP_SIZE EQU 4768
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
	ld de, __LABEL0
	ld hl, _b
	call __STORE_STR
	ld hl, (_b)
	xor a
	call VAL
	call __STR_FAST
	ex de, hl
	ld hl, _a
	call __STORE_STR2
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
__CALL_BACK__:
	DEFW 0
__LABEL0:
	DEFW 0002h
	DEFB 31h
	DEFB 30h
#line 1 "storestr.asm"
; vim:ts=4:et:sw=4
	; Stores value of current string pointed by DE register into address pointed by HL
	; Returns DE = Address pointer  (&a$)
	; Returns HL = HL               (b$ => might be needed later to free it from the heap)
	;
	; e.g. => HL = _variableName    (DIM _variableName$)
	;         DE = Address into the HEAP
	;
	; This function will resize (REALLOC) the space pointed by HL
	; before copying the content of b$ into a$
	
	
#line 1 "strcpy.asm"
#line 1 "realloc.asm"
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
	
	
#line 1 "error.asm"
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
#line 70 "realloc.asm"
#line 1 "alloc.asm"
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
	; if we can defragment the heap. If the block to be freed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	
	
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with 
	; HL = BLOCK Start & DE = Length.
	
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	
	
#line 1 "heapinit.asm"
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
	
#line 70 "alloc.asm"
	
	
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
#line 111 "/Users/boriel/Documents/src/zxbasic/library-asm/alloc.asm"
	        ret z ; NULL
#line 113 "/Users/boriel/Documents/src/zxbasic/library-asm/alloc.asm"
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
	
	
#line 71 "realloc.asm"
#line 1 "free.asm"
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
	
#line 72 "realloc.asm"
	
	
	; ---------------------------------------------------------------------
	; MEM_REALLOC
	;  Reallocates a block of memory in the heap.
	;
	; Parameters
	;  HL = Pointer to the original block
	;  BC = New Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	;
; Notes:
	;  If BC = 0, the block is freed, otherwise
	;  the content of the original block is copied to the new one, and
	;  the new size is adjusted. If BC < original length, the content
	;  will be truncated. Otherwise, extra block content might contain
	;  memory garbage.
	;  
	; ---------------------------------------------------------------------
__REALLOC:    ; Reallocates block pointed by HL, with new length BC
	        PROC
	
	        LOCAL __REALLOC_END
	
	        ld a, h
	        or l
	        jp z, __MEM_ALLOC    ; If HL == NULL, just do a malloc
	
	        ld e, (hl)
	        inc hl
	        ld d, (hl)    ; DE = First 2 bytes of HL block
	
	        push hl
	        exx
	        pop de
	        inc de        ; DE' <- HL + 2
	        exx            ; DE' <- HL (Saves current pointer into DE')
	
	        dec hl        ; HL = Block start
	
	        push de
	        push bc
	        call __MEM_FREE        ; Frees current block
	        pop bc
	        push bc
	        call __MEM_ALLOC    ; Gets a new block of length BC
	        pop bc
	        pop de
	
	        ld a, h
	        or l
	        ret z        ; Return if HL == NULL (No memory)
	        
	        ld (hl), e
	        inc hl
	        ld (hl), d
	        inc hl        ; Recovers first 2 bytes in HL
	
	        dec bc
	        dec bc        ; BC = BC - 2 (Two bytes copied)
	
	        ld a, b
	        or c
	        jp z, __REALLOC_END        ; Ret if nothing to copy (BC == 0)
	
	        exx
	        push de
	        exx
	        pop de        ; DE <- DE' ; Start of remaining block
	
	        push hl        ; Saves current Block + 2 start
        ex de, hl    ; Exchanges them: DE is destiny block
	        ldir        ; Copies BC Bytes
	        pop hl        ; Recovers Block + 2 start
	
__REALLOC_END:
	
	        dec hl        ; Set HL
	        dec hl        ; To begin of block
	        ret
	
	        ENDP
	
#line 2 "strcpy.asm"
	
	; String library
	
	
__STRASSIGN: ; Performs a$ = b$ (HL = address of a$; DE = Address of b$)
			PROC
	
			LOCAL __STRREALLOC
			LOCAL __STRCONTINUE
			LOCAL __B_IS_NULL
			LOCAL __NOTHING_TO_COPY
	
			ld b, d
			ld c, e
			ld a, b
			or c
			jr z, __B_IS_NULL
	
			ex de, hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			dec hl		; BC = LEN(b$)
			ex de, hl	; DE = &b$
	
__B_IS_NULL:		; Jumps here if B$ pointer is NULL
			inc bc
			inc bc		; BC = BC + 2  ; (LEN(b$) + 2 bytes for storing length)
	
			push de
			push hl
	
			ld a, h
			or l
			jr z, __STRREALLOC
	
			dec hl
			ld d, (hl)
			dec hl
			ld e, (hl)	; DE = MEMBLOCKSIZE(a$)
			dec de
			dec de		; DE = DE - 2  ; (Membloksize takes 2 bytes for memblock length)
	
			ld h, b
			ld l, c		; HL = LEN(b$) + 2  => Minimum block size required
			ex de, hl	; Now HL = BLOCKSIZE(a$), DE = LEN(b$) + 2
	
			or a		; Prepare to subtract BLOCKSIZE(a$) - LEN(b$)
			sbc hl, de  ; Carry if len(b$) > Blocklen(a$)
			jr c, __STRREALLOC ; No need to realloc
			; Need to reallocate at least to len(b$) + 2
			ex de, hl	; DE = Remaining bytes in a$ mem block.
			ld hl, 4	
			sbc hl, de  ; if remaining bytes < 4 we can continue
			jr nc,__STRCONTINUE ; Otherwise, we realloc, to free some bytes
	
__STRREALLOC:
			pop hl
			call __REALLOC	; Returns in HL a new pointer with BC bytes allocated
			push hl 
	
__STRCONTINUE:	;   Pops hl and de SWAPPED
			pop de	;	DE = &a$
			pop hl	; 	HL = &b$
	
			ld a, d		; Return if not enough memory for new length
			or e
			ret z		; Return if DE == NULL (0)
	
__STRCPY:	; Copies string pointed by HL into string pointed by DE
				; Returns DE as HL (new pointer)
			ld a, h
			or l
			jr z, __NOTHING_TO_COPY
			ld c, (hl)
			inc hl
			ld b, (hl)
			dec hl
			inc bc
			inc bc
			push de
			ldir
			pop hl
			ret
	
__NOTHING_TO_COPY:
			ex de, hl
			ld (hl), e
			inc hl
			ld (hl), d
			dec hl
			ret
	
			ENDP
	
#line 14 "storestr.asm"
	
__PISTORE_STR:          ; Indirect assignement at (IX + BC)
	    push ix
	    pop hl
	    add hl, bc
	
__ISTORE_STR:           ; Indirect assignement, hl point to a pointer to a pointer to the heap!
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c             ; HL = (HL)
	
__STORE_STR:
	    push de             ; Pointer to b$
	    push hl             ; Array pointer to variable memory address
	
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c             ; HL = (HL)
	
	    call __STRASSIGN    ; HL (a$) = DE (b$); HL changed to a new dynamic memory allocation
	    ex de, hl           ; DE = new address of a$
	    pop hl              ; Recover variable memory address pointer
	
	    ld (hl), e
	    inc hl
	    ld (hl), d          ; Stores a$ ptr into elemem ptr
	
	    pop hl              ; Returns ptr to b$ in HL (Caller might needed to free it from memory)
	    ret
	
#line 32 "loadstr.bas"
#line 1 "storestr2.asm"
	; Similar to __STORE_STR, but this one is called when
	; the value of B$ if already duplicated onto the stack.
	; So we needn't call STRASSING to create a duplication
	; HL = address of string memory variable
	; DE = address of 2n string. It just copies DE into (HL)
	; 	freeing (HL) previously.
	
	
	
__PISTORE_STR2: ; Indirect store temporary string at (IX + BC)
	    push ix
	    pop hl
	    add hl, bc
	
__ISTORE_STR2:
		ld c, (hl)  ; Dereferences HL
		inc hl
		ld h, (hl)
		ld l, c		; HL = *HL (real string variable address)
	
__STORE_STR2:
		push hl
		ld c, (hl)
		inc hl
		ld h, (hl)
		ld l, c		; HL = *HL (real string address)
	
		push de
		call __MEM_FREE
		pop de
	
		pop hl
		ld (hl), e
		inc hl
		ld (hl), d
		dec hl		; HL points to mem address variable. This might be useful in the future.
	
		ret
	
#line 33 "loadstr.bas"
#line 1 "str.asm"
	; The STR$( ) BASIC function implementation
	
	; Given a FP number in C ED LH
	; Returns a pointer (in HL) to the memory heap
	; containing the FP number string representation
	
	
#line 1 "stackf.asm"
	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------
	
	
	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)
	
__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	                 ; Second argument to push into the stack calculator is popped out of the stack
	                 ; Since the caller routine also receives the parameters into the top of the stack
	                 ; four bytes must be removed from SP before pop them out
	
	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr
	
	    pop af
	    pop de
	    pop bc
	
	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx
	 
	    jp __FPSTACK_PUSH
	
	
__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
					; This format is specified in the ZX 48K Manual
					; You can push a 16 bit signed integer as
					; 0 SS LL HH 0, being SS the sign and LL HH the low
					; and High byte respectively
		ld a, h
		rla			; sign to Carry
		sbc	a, a	; 0 if positive, FF if negative
		ld e, a
		ld d, l
		ld c, h
		xor a
		ld b, a
		jp __FPSTACK_PUSH
#line 9 "str.asm"
#line 1 "const.asm"
	; Global constants
	
	P_FLAG	EQU 23697
	FLAGS2	EQU 23681
	ATTR_P	EQU 23693	; permanet ATTRIBUTES
	ATTR_T	EQU 23695	; temporary ATTRIBUTES
	CHARS	EQU 23606 ; Pointer to ROM/RAM Charset
	UDG	EQU 23675 ; Pointer to UDG Charset
	MEM0	EQU 5C92h ; Temporary memory buffer used by ROM chars
	
#line 10 "str.asm"
	
__STR:
	
__STR_FAST:
	
		PROC
		LOCAL __STR_END
		LOCAL RECLAIM2
		LOCAL STK_END
	
		ld hl, (STK_END)
		push hl; Stores STK_END
		ld hl, (ATTR_T)	; Saves ATTR_T since it's changed by STR$ due to a ROM BUG
		push hl
	
	    call __FPSTACK_PUSH ; Push number into stack
		rst 28h		; # Rom Calculator
		defb 2Eh	; # STR$(x)
		defb 38h	; # END CALC
		call __FPSTACK_POP ; Recovers string parameters to A ED CB (Only ED LH are important)
	
		pop hl
		ld (ATTR_T), hl	; Restores ATTR_T
		pop hl
		ld (STK_END), hl	; Balance STK_END to avoid STR$ bug
	
		push bc
		push de
	
		inc bc
		inc bc
		call __MEM_ALLOC ; HL Points to new block
	
		pop de
		pop bc
	
		push hl
		ld a, h
		or l
		jr z, __STR_END  ; Return if NO MEMORY (NULL)
	
		push bc
		push de
		ld (hl), c	
		inc hl
		ld (hl), b
		inc hl		; Copies length
	
		ex de, hl	; HL = start of original string
		ldir		; Copies string content
	
		pop de		; Original (ROM-CALC) string
		pop bc		; Original Length
		
__STR_END:
		ex de, hl
		inc bc
	
		call RECLAIM2 ; Frees TMP Memory
		pop hl		  ; String result
	
		ret
	
	RECLAIM2 EQU 19E8h
	STK_END EQU 5C65h
	
		ENDP
	
#line 34 "loadstr.bas"
#line 1 "val.asm"
	
	
	
	
VAL: ; Computes VAL(a$) using ROM FP-CALC
		 ; HL = address of a$
		 ; Returns FP number in C ED LH registers
		 ; A Register = 1 => Free a$ on return
		
		PROC
	
		LOCAL STK_STO_S
		LOCAL __RET_ZERO
		LOCAL ERR_SP
		LOCAL STKBOT
		LOCAL RECLAIM1
	    LOCAL CH_ADD
		LOCAL __VAL_ERROR
		LOCAL __VAL_EMPTY
	    LOCAL SET_MIN
	
	RECLAIM1	EQU 6629
	STKBOT		EQU 23651
	ERR_SP		EQU 23613
	CH_ADD      EQU 23645
	STK_STO_S	EQU	2AB2h
	SET_MIN     EQU 16B0h
	
	    ld d, a ; Preserves A register in DE
		ld a, h
		or l
		jr z, __RET_ZERO ; NULL STRING => Return 0 
	
	    push de ; Saves A Register (now in D)
		push hl	; Not null string. Save its address for later
	
		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl
	
		ld a, b
		or c
		jr z, __VAL_EMPTY ; Jumps VAL_EMPTY on empty string
	
		ex de, hl ; DE = String start
	
	    ld hl, (CH_ADD)
	    push hl
	
		ld hl, (STKBOT)
		push hl
	
		ld hl, (ERR_SP)
		push hl
	
	    ;; Now put our error handler on ERR_SP
		ld hl, __VAL_ERROR
		push hl
		ld hl, 0
		add hl, sp
		ld (ERR_SP), hl
	
		call STK_STO_S ; Enter it on the stack
	
		ld b, 1Dh ; "VAL"
		rst 28h	; ROM CALC
		defb 1Dh ; VAL
		defb 38h ; END CALC
	
		pop hl 	; Discards our current error handler
		pop hl
		ld (ERR_SP), hl	; Restores ERR_SP
	
		pop de	         ; old STKBOT
		ld hl, (STKBOT)  ; current SKTBOT
		call	RECLAIM1 ; Recover unused space
	
	    pop hl  ; Discards old CH_ADD value
		pop hl 	; String pointer
		pop af	; Deletion flag
		or a
		call nz, __MEM_FREE	; Frees string content before returning
	
	    ld a, ERROR_Ok      ; Sets OK in the result
	    ld (ERR_NR), a
	
		jp __FPSTACK_POP	; Recovers result and return from there
	
__VAL_ERROR:	; Jumps here on ERROR
		pop hl
		ld (ERR_SP), hl ; Restores ERR_SP
	
		ld hl, (STKBOT)  ; current SKTBOT
		pop de	; old STKBOT
	    pop hl
	    ld (CH_ADD), hl  ; Recovers old CH_ADD
	
	    call 16B0h       ; Resets temporary areas after an error
	
__VAL_EMPTY:	; Jumps here on empty string
		pop hl      ; Recovers initial string address
	pop af      ; String flag: If not 0 => it's temporary
		or a
		call nz, __MEM_FREE ; Frees "" string
	
__RET_ZERO:	; Returns 0 Floating point on error
		ld a, ERROR_Ok
		ld (ERR_NR), a
	
		xor a
		ld b, a
		ld c, a
		ld d, b
		ld e, c
		ret
	
		ENDP
	
#line 35 "loadstr.bas"
	
ZXBASIC_USER_DATA:
_b:
	DEFB 00, 00
_a:
	DEFB 00, 00
ZXBASIC_MEM_HEAP:
	; Defines DATA END
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
