; Copyleft (K) by Jose M. Rodriguez de la Rosa
;  (a.k.a. Boriel)
;  http://www.boriel.com
;
; This ASM library is licensed under the MIT license
; you can use it for any purpose (even for commercial
; closed source programs).

; Copy-on-Write routines
; We need now an extra byte as reference counter.


#include once <cow/cow_mem_alloc.asm>
#include once <cow/cow_mem_free.asm>
#include once <realloc.asm>

push namespace core


; ---------------------------------------------------------------------
; COW_MEM_REALLOC
; ReAllocates a block of memory in the heap.
;
; Parameters
;  HL = Pointer to the current block of memory.
;       If HL=0 it's equivalent to a COW_MEM_ALLOC
;  BC = Length of requested memory block
;       If BC=0 it's equivalent to a COW_MEM_FREE
;
; Returns:
;  HL = Pointer to the allocated block in memory.
;       Returns 0 (NULL) and Z flag set
;       if the block could not be allocated (out of memory).
;
; ---------------------------------------------------------------------

COW_MEM_REALLOC:
    PROC
    LOCAL NO_REALLOC

    ld a, h
    or l
    jp z, COW_MEM_ALLOC
    ld a, b
    or c
    jp z, COW_MEM_FREE
    dec hl
    dec (hl)
    jr nz, NO_REALLOC

    inc bc            ; +1 to size for Ref counter
    call MEM_REALLOC  ; Does a normal realloc
    ld a, h
    or l
    ret z             ; returns if Out of Memory
    ld (hl), 1        ; Sets the ref count and return
    inc hl
    ret

NO_REALLOC:
    dec bc
    inc hl
    push hl
    push bc
    call COW_MEM_ALLOC
    pop bc          ; Original requested size
    pop de          ; Original block ptr
    ld a, h
    or l
    ret z           ; return if Out of memory

    ; Now copies BC bytes from block pointed by DE (origin) into block pointed by HL (destination)
    push hl         ; Saves it to return it later
    ex de, hl       ; Swaps regs. DE must be destination
    ldir
    pop hl          ; returns it in HL
    ret

pop namespace
