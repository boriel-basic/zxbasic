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

#init "__MEM_INIT"

#include once <error.asm>


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
        LOCAL RAMTOP

        ld (RAMTOP), hl ; Initializes library

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
        LOCAL __MEM_LOOP
        LOCAL __MEM_DONE
        LOCAL __MEM_SUBTRACT
        LOCAL __MEM_START
        LOCAL TEMP

        ld hl, 0
        ld (TEMP), hl

RAMTOP  EQU __MEM_START + 1
__MEM_START:
        ld hl, 0000h ; This address will be "poked" with real value of heap start
        inc bc
        inc bc  ; BC = BC + 2 ; block size needs 2 extra bytes for hidden pointer
        
__MEM_LOOP:  ; Loads lengh at (HL, HL+). If Lenght >= BC, jump to __MEM_DONE
        ld a, h ;  HL = NULL (No memory available?)
        or l
#ifdef __MEMORY_CHECK__
        ld a, ERROR_OutOfMemory
        jp z, __ERROR
#else
        ret z ; NULL
#endif
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
        ld hl, (TEMP) ; Pre-previous block pointer

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
            
TEMP   EQU 23563   ; DEFADD variable


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

        ld hl, (RAMTOP)

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


; ---------------------------------------------------------------------
; MEM_ALLOC
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

