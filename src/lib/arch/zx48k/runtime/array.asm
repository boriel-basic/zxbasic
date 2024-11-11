; vim: ts=4:et:sw=4:
; Copyleft (K) by Jose M. Rodriguez de la Rosa
;  (a.k.a. Boriel)
;  http://www.boriel.com
; -------------------------------------------------------------------
; Simple array Index routine
; Number of total indexes dimensions - 1 at beginning of memory
; HL = Start of array memory (First two bytes contains N-1 dimensions)
; Dimension values on the stack, (top of the stack, highest dimension)
; E.g. A(2, 4) -> PUSH <4>; PUSH <2>

; For any array of N dimension A(aN-1, ..., a1, a0)
; and dimensions D[bN-1, ..., b1, b0], the offset is calculated as
; O = [a0 + b0 * (a1 + b1 * (a2 + ... bN-2(aN-1)))]
; What I will do here is to calculate the following sequence:
; ((aN-1 * bN-2) + aN-2) * bN-3 + ...


#include once <mul16.asm>

#ifdef __CHECK_ARRAY_BOUNDARY__
#include once <error.asm>
#endif

    push namespace core

__ARRAY_PTR:   ;; computes an array offset from a pointer
    ld c, (hl)
    inc hl
    ld h, (hl)
    ld l, c    ;; HL <-- [HL]

__ARRAY:
    PROC

    LOCAL LOOP
    LOCAL ARRAY_END
    LOCAL TMP_ARR_PTR            ; Ptr to Array DATA region. Stored temporarily
    LOCAL LBOUND_PTR, RET_ADDR

LBOUND_PTR EQU 23698  ; Uses MEMBOT as a temporary variable
RET_ADDR EQU 23700
TMP_ARR_PTR EQU 23702

    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl      ; DE <-- PTR to Dim sizes table
    ld (TMP_ARR_PTR), hl  ; HL = Array __DATA__.__PTR__
    inc hl
    inc hl
    ld c, (hl)
    inc hl
    ld b, (hl)  ; BC <-- Array __LBOUND__ PTR
    ld (LBOUND_PTR), bc  ; Store it for later
    ex de, hl   ; HL <-- PTR to Dim sizes table, DE <-- dummy
    ex (sp), hl	; Return address in HL, PTR Dim sizes table onto Stack
    ld (RET_ADDR), hl ; Stores it for later

    exx
    pop hl		; Will use H'L' as the pointer to Dim sizes table
    ld c, (hl)	; Loads Number of dimensions from (hl)
    inc hl
    ld b, (hl)
    inc hl		; Ready
    exx

    ld hl, 0	; HL = Element Offset "accumulator"

LOOP:
    ex de, hl   ; DE = Element Offset
    ld hl, (LBOUND_PTR)
    ld a, h
    or l
    ld bc, 0
    jr z, 1f
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld (LBOUND_PTR), hl
1:
    pop hl      ; Get next index (Ai) from the stack
    sbc hl, bc  ; Subtract LBOUND

#ifdef __CHECK_ARRAY_BOUNDARY__
    ld a, ERROR_SubscriptWrong
    jp c, __ERROR
    pop bc
    scf
    sbc hl, bc
    jp nc, __ERROR
    adc hl, bc  ; Recovers original value
#endif

    add hl, de	; Adds current index

    exx			; Checks if B'C' = 0
    ld a, b		; Which means we must exit (last element is not multiplied by anything)
    or c
    jr z, ARRAY_END		; if B'Ci == 0 we are done
    dec bc				; Decrements loop counter

    ld e, (hl)			; Loads next dimension size into D'E'
    inc hl
    ld d, (hl)
    inc hl
    push de
    exx

    pop de				; DE = Max bound Number (i-th dimension)

    call __FNMUL        ; HL <= HL * DE mod 65536
    jp LOOP

ARRAY_END:
    ld a, (hl)
    exx

#ifdef __BIG_ARRAY__
    ld d, 0
    ld e, a
    call __FNMUL
#else
    LOCAL ARRAY_SIZE_LOOP

    ex de, hl
    ld hl, 0
    ld b, a
ARRAY_SIZE_LOOP:
    add hl, de
    djnz ARRAY_SIZE_LOOP

#endif

    ex de, hl
    ld hl, (TMP_ARR_PTR)
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    add hl, de  ; Adds element start
    ld de, (RET_ADDR)
    push de
    ret

    ;; Performs a faster multiply for little 16bit numbs
    LOCAL __FNMUL, __FNMUL2

__FNMUL:
    xor a
    or h
    jp nz, __MUL16_FAST
    or l
    ret z

    cp 33
    jp nc, __MUL16_FAST

    ld b, l
    ld l, h  ; HL = 0

__FNMUL2:
    add hl, de
    djnz __FNMUL2
    ret

    ENDP

    pop namespace
