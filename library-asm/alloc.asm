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

#include once <error.asm>
#include once <heapinit.asm>


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


