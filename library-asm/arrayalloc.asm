
#include once <calloc.asm>


; ---------------------------------------------------------------------
; __ALLOC_LOCAL_ARRAY
;  Allocates an array element area in the heap, and clears it filling it
;  with 0 bytes
;
; Parameters
;  HL = Offset to be added to IX => HL = IX + HL
;  BC = Length of the element area = n.elements * size(element)
;  DE = PTR to the index table
;
; Returns:
;  HL = (IX + HL) + 4
; ---------------------------------------------------------------------

__ALLOC_LOCAL_ARRAY:
    push de
    push ix
    pop de
    add hl, de  ; hl = ix + hl
    pop de
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    push hl
    call __MEM_CALLOC
    pop de
    ex de, hl
    ld (hl), e
    inc hl
    ld (hl), d
    ret


; ---------------------------------------------------------------------
; __ALLOC_INITIALIZED_LOCAL_ARRAY
;  Allocates an array element area in the heap, and clears it filling it
;  with 0 bytes
;
; Parameters
;  HL = Offset to be added to IX => HL = IX + HL
;  BC = Length of the element area = n.elements * size(element)
;  DE = PTR to the index table
;  TOP of the stack = PTR to the element area
; Returns:
;  Nothing
; ---------------------------------------------------------------------

__ALLOC_INITIALIZED_LOCAL_ARRAY:
    push bc
    call __ALLOC_LOCAL_ARRAY
    pop bc
    pop hl
    ex (sp), hl
    ; HL = data table
    ; BC = length
    ; DE = new data area
    ldir
    ret
