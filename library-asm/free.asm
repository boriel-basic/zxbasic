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

#include once <heapinit.asm>

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

