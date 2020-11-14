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

