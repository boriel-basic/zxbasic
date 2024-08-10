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

push namespace core

; ---------------------------------------------------------------------
; COW_COPY_BLOCK:
;  Returns a "shallow" copy of the given block. If the ref counter is
;  less that 255 will increase the counter and return the same ptr.
;  Otherwise, creates a duplicated block.
;
; Parameters
;  HL = Pointer to the already allocated block.
;
; Returns:
;  HL = Pointer to the copied block in memory. Returns 0 (NULL)
;       if the block could not be allocated (out of memory)
; ---------------------------------------------------------------------

COW_COPY_BLOCK:
    dec hl
    inc (hl)
    inc hl
    ret nz

    ; at this point we need to duplicate the block
    dec hl
    dec (hl)        ; Recovers ref counter
    inc hl          ; points to the block again

    ; At this point we enter the COPY_DUP_BLOCK routine and return
    ; from there.

; ---------------------------------------------------------------------
; COW_DUP_BLOCK:
;  Returns a duplicated copy of the given block regardless of its
;  ref counter (which is set to 1 in the new block). The original block
;  is left untouched.
;
; Parameters
;  HL = Pointer to the already allocated block.
;
; Returns:
;  HL = Pointer to the copied block in memory. Returns 0 (NULL)
;       if the block could not be allocated (out of memory)
; ---------------------------------------------------------------------

COW_DUP_BLOCK:
    ; Recovers original block size
    push hl
    dec hl          ; points to ref counter
    dec hl          ; points to end of length
    ld b, (hl)
    dec hl
    ld c, (hl)      ; BC = (HL) = Size of allocated block + 1 for the ref counter.
    dec bc          ; The byte of the refcount is not needed
    push bc         ; saves size for later
    call COW_MEM_ALLOC
    pop bc          ; BC = original length
    pop de          ; DE = original block PTR
    ret z           ; Returns if No memory
    ; Now copies the old block content onto the new one
    push hl         ; Saves ptr to new block to return it later
    ex de, hl       ; DE = new block PTR, HL = original block PTR, BC = length
    ldir            ; Copy original block content into new one
    pop hl
    ret

pop namespace
