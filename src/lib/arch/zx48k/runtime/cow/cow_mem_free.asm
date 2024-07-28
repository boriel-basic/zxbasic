; Copyleft (K) by Jose M. Rodriguez de la Rosa
;  (a.k.a. Boriel)
;  http://www.boriel.com
;
; This ASM library is licensed under the MIT license
; you can use it for any purpose (even for commercial
; closed source programs).

; Copy-on-Write routines
; We need now an extra byte as reference counter.


#include <free.asm>

push namespace core


; ---------------------------------------------------------------------
; COW_MEM_FREE
;  Frees a block of memory pointed by HL
;
; Parameters:
;  HL = Pointer to the block to be freed. If HL is NULL (0) this could
;  crash the program.
;
; NOTE: This is CoW (Copy on Write) implementation. HL - 1 contains
; the reference counter. This will decrease the refcounter first, and
; only free the block from memory if the counter reaches 0
; ---------------------------------------------------------------------

; Implemented in free.asm directly as it's so simply.
COW_MEM_FREE EQU __COW_FREE

pop namespace core
