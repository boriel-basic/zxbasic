; Copyleft (K) by Jose M. Rodriguez de la Rosa
;  (a.k.a. Boriel)
;  http://www.boriel.com
;
; This ASM library is licensed under the MIT license
; you can use it for any purpose (even for commercial
; closed source programs).

; Copy-on-Write routines
; We need now an extra byte as reference counter.


#include once <alloc.asm>

push namespace core


; ---------------------------------------------------------------------
; COW_MEM_ALLOC
; Allocates a block of memory in the heap.
;
; Parameters
;  BC = Length of requested memory block
;
; Returns:
;  HL = Pointer to the allocated block in memory.
;       Returns 0 (NULL) and Z flag set
;       if the block could not be allocated (out of memory).
; ---------------------------------------------------------------------

COW_MEM_ALLOC:
    inc bc          ; Ref counter
    call MEM_ALLOC
    ld a, h         ; Maybe this and the following line are not needed?
    or l
    ret z           ; Out of memory. Return NULL
    ld (hl), 1      ; Set reference counter to 1
    inc hl
    ret

pop namespace
