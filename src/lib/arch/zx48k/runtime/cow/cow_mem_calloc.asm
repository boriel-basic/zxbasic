; Copyleft (K) by Jose M. Rodriguez de la Rosa
;  (a.k.a. Boriel)
;  http://www.boriel.com
;
; This ASM library is licensed under the MIT license
; you can use it for any purpose (even for commercial
; closed source programs).

; Copy-on-Write routines
; We need now an extra byte as reference counter.


#include once <calloc.asm>

push namespace core


; ---------------------------------------------------------------------
; COW_MEM_CALLOC
; Allocates a block of memory in the heap, clearing it with 0's
;
; Parameters
;  BC = Length of requested memory block
;
; Returns:
;  HL = Pointer to the allocated block in memory.
;       Returns 0 (NULL) and Z flag set
;       if the block could not be allocated (out of memory).
; ---------------------------------------------------------------------

COW_MEM_CALLOC:
    inc bc          ; Ref counter
    call MEM_CALLOC
    ld a, h
    or l
    ret z           ; Out of memory. Return NULL
    ld (hl), 1      ; Set reference counter to 1
    inc hl
    ret

pop namespace
