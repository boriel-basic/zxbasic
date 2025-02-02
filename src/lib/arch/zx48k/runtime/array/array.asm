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


#include once <arith/fmul16.asm>

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
    LOCAL LBOUND_PTR, UBOUND_PTR ; LBound and UBound PTR indexes
    LOCAL RET_ADDR               ; Contains the return address popped from the stack

LBOUND_PTR EQU 23698           ; Uses MEMBOT as a temporary variable
UBOUND_PTR EQU LBOUND_PTR + 2  ; Next 2 bytes for UBOUND PTR
RET_ADDR EQU UBOUND_PTR + 2    ; Next 2 bytes for RET_ADDR
TMP_ARR_PTR EQU RET_ADDR + 2   ; Next 2 bytes for TMP_ARR_PTR

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

#ifdef __CHECK_ARRAY_BOUNDARY__
    inc hl
    ld c, (hl)
    inc hl
    ld b, (hl)  ; BC <-- Array __UBOUND__ PTR
    ld (UBOUND_PTR), bc
#endif

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
    ld b, h
    ld c, l
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
    push hl     ; Saves (Ai) - Lbound(i)
    add hl, bc  ; Recover original (Ai) value
    push hl
    ld hl, (UBOUND_PTR)
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld (UBOUND_PTR), hl
    pop hl      ; original (Ai) value
    scf
    sbc hl, bc  ; HL <- HL - BC - 1 = Ai - UBound(i) - 1 => No Carry if Ai > UBound(i)
    jp nc, __ERROR
    pop hl  ; Recovers (Ai) - Lbound(Ai)
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

    call __FMUL16        ; HL <= HL * DE mod 65536
    jp LOOP

ARRAY_END:
    ld a, (hl)
    exx

#ifdef __BIG_ARRAY__
    ld d, 0
    ld e, a
    call __FMUL16
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

    ENDP

    pop namespace
