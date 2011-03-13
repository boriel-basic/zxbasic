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


#include once <error.asm>
#include once <alloc.asm>
#include once <free.asm>


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

