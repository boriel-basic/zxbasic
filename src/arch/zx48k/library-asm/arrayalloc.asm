
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
;  [SP + 2] = PTR to the element area
;
; Returns:
;  HL = (IX + HL) + 4
; ---------------------------------------------------------------------

__ALLOC_INITIALIZED_LOCAL_ARRAY:
    push bc
    call __ALLOC_LOCAL_ARRAY
    pop bc
    ;; Swaps [SP], [SP + 2]
    exx
    pop hl       ; HL <- RET address
    ex (sp), hl  ; HL <- Data table, [SP] <- RET address
    push hl      ; [SP] <- Data table
    exx
    ex (sp), hl  ; HL = Data table, (SP) = (IX + HL + 4) - start of array address lbound
    ; HL = data table
    ; BC = length
    ; DE = new data area
    ldir
    pop hl  ; HL = addr of LBound area if used
    ret


#ifdef __ZXB_USE_LOCAL_ARRAY_WITH_BOUNDS__

; ---------------------------------------------------------------------
; __ALLOC_LOCAL_ARRAY_WITH_BOUNDS
;  Allocates an array element area in the heap, and clears it filling it
;  with 0 bytes. Then sets LBOUND and UBOUND ptrs
;
; Parameters
;  HL = Offset to be added to IX => HL = IX + HL
;  BC = Length of the element area = n.elements * size(element)
;  DE = PTR to the index table
;  [SP + 2] PTR to the lbound element area
;  [SP + 4] PTR to the ubound element area
;
; Returns:
;  HL = (IX + HL) + 8
; ---------------------------------------------------------------------
__ALLOC_LOCAL_ARRAY_WITH_BOUNDS:
    call __ALLOC_LOCAL_ARRAY

__ALLOC_LOCAL_ARRAY_WITH_BOUNDS2:
    pop bc   ;; ret address
    pop de   ;; lbound
    inc hl
    ld (hl), e
    inc hl
    ld (hl), d
    pop de
    inc hl
    ld (hl), e
    inc hl
    ld (hl), d
    push bc
    ret


; ---------------------------------------------------------------------
; __ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS
;  Allocates an array element area in the heap, and clears it filling it
;  with 0 bytes
;
; Parameters
;  HL = Offset to be added to IX => HL = IX + HL
;  BC = Length of the element area = n.elements * size(element)
;  DE = PTR to the index table
;  TOP of the stack = PTR to the element area
;  [SP + 2] = PTR to the element area
;  [SP + 4] = PTR to the lbound element area
;  [SP + 6] = PTR to the ubound element area
;
; Returns:
;  HL = (IX + HL) + 8
; ---------------------------------------------------------------------
__ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS:
    ;; Swaps [SP] and [SP + 2]
    exx
    pop hl       ;; Ret address
    ex (sp), hl  ;; HL <- PTR to Element area, (sp) = Ret address
    push hl      ;; [SP] = PTR to element area, [SP + 2] = Ret address
    exx
    call __ALLOC_INITIALIZED_LOCAL_ARRAY
    jp __ALLOC_LOCAL_ARRAY_WITH_BOUNDS2

#endif
