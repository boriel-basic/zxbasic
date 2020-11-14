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

#include once <alloc.asm>


; ---------------------------------------------------------------------
; MEM_CALLOC
;  Allocates a block of memory in the heap, and clears it filling it
;  with 0 bytes
;
; Parameters
;  BC = Length of requested memory block
;
; Returns:
;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
;       if the block could not be allocated (out of memory)
; ---------------------------------------------------------------------
__MEM_CALLOC:
        push bc
        call __MEM_ALLOC
        pop bc
        ld a, h
        or l
        ret z  ; No memory
        ld (hl), 0
        dec bc
        ld a, b
        or c
        ret z  ; Already filled (1 byte-length block)
        ld d, h
        ld e, l
        inc de
        push hl
        ldir
        pop hl
        ret
