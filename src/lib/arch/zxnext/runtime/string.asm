; String library

#include once <free.asm>
#include once <strlen.asm>

    push namespace core

__STR_ISNULL:	; Returns A = FF if HL is 0, 0 otherwise
    ld a, h
    or l
    sub 1		; Only CARRY if HL is NULL
    sbc a, a	; Only FF if HL is NULL (0 otherwise)
    ret


__STRCMP:	; Compares strings at HL (a$), DE (b$)
            ; Returns 0 if EQual, -1 if HL < DE, +1 if HL > DE
    ; A register is preserved and returned in A'
    PROC ; __FASTCALL__

    LOCAL __STRCMPZERO
    LOCAL __STRCMPEXIT
    LOCAL __STRCMPLOOP
    LOCAL __EQULEN1
    LOCAL __HLZERO

    ex af, af'	; Saves current A register in A' (it's used by STRXX comparison functions)

    push hl
    call __STRLEN
    ld a, h
    or l
    pop hl
    jr z, __HLZERO  ; if HL == "", go to __HLZERO

    push de
    ex de, hl
    call __STRLEN
    ld a, h
    or l
    ld a, 1
    ex de, hl   ; Recovers HL
    pop de
    ret z		; Returns +1 if HL != "" AND DE == ""

    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl		; BC = LEN(a$)
    push hl		; HL = &a$, saves it

    ex de, hl
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ex de, hl	; HL = LEN(b$), de = &b$

    ; At this point Carry is cleared, and A reg. = 1
    sbc hl, bc	     ; Carry if len(a$)[BC] > len(b$)[HL]

    ld a, 0
    jr z, __EQULEN1	 ; Jumps if len(a$)[BC] = len(b$)[HL] : A = 0

    dec a
    jr nc, __EQULEN1 ; Jumps if len(a$)[BC] < len(b$)[HL] : A = 1

    adc hl, bc  ; Restores HL
    ld a, 1     ; Signals len(a$)[BC] > len(b$)[HL] : A = 1
    ld b, h
    ld c, l

__EQULEN1:
    pop hl		; Recovers A$ pointer
    push af		; Saves A for later (Value to return if strings reach the end)
    ld a, b
    or c
    jr z, __STRCMPZERO ; empty string being compared

    ; At this point: BC = lesser length, DE and HL points to b$ and a$ chars respectively
__STRCMPLOOP:
    ld a, (de)
    cpi
    jr nz, __STRCMPEXIT ; (HL) != (DE). Examine carry
    jp po, __STRCMPZERO ; END of string (both are equal)
    inc de
    jp __STRCMPLOOP

__STRCMPZERO:
    pop af		; This is -1 if len(a$) < len(b$), +1 if len(b$) > len(a$), 0 otherwise
    ret

__STRCMPEXIT:		; Sets A with the following value
    dec hl		; Get back to the last char
    cp (hl)
    sbc a, a	; A = -1 if carry => (DE) < (HL); 0 otherwise (DE) > (HL)
    cpl			; A = -1 if (HL) < (DE), 0 otherwise
    add a, a    ; A = A * 2 (thus -2 or 0)
    inc a		; A = A + 1 (thus -1 or 1)

    pop bc		; Discard top of the stack
    ret

__HLZERO:
    ex de, hl
    call __STRLEN
    ld a, h
    or l
    ret z		; Returns 0 (EQ) if HL == DE == ""
    ld a, -1
    ret			; Returns -1 if HL == "" and DE != ""

    ENDP

    ; The following routines perform string comparison operations (<, >, ==, etc...)
    ; On return, A will contain 0 for False, other value for True
    ; Register A' will determine whether the incoming strings (HL, DE) will be freed
    ; from dynamic memory on exit:
    ;		Bit 0 => 1 means HL will be freed.
    ;		Bit 1 => 1 means DE will be freed.

__STREQ:	; Compares a$ == b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl
    sub 1
    sbc a, a
    jp __FREE_STR


__STRNE:	; Compares a$ != b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl
    jp __FREE_STR


__STRLT:	; Compares a$ < b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl
    or a
    jp z, __FREE_STR ; Returns 0 if A == B

    dec a		; Returns 0 if A == 1 => a$ > b$
    jp __FREE_STR


__STRLE:	; Compares a$ <= b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl

    dec a		; Returns 0 if A == 1 => a$ < b$
    jp __FREE_STR


__STRGT:	; Compares a$ > b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl
    or a
    jp z, __FREE_STR		; Returns 0 if A == B

    inc a		; Returns 0 if A == -1 => a$ < b$
    jp __FREE_STR


__STRGE:	; Compares a$ >= b$ (HL = ptr a$, DE = ptr b$). Returns FF (True) or 0 (False)
    push hl
    push de
    call __STRCMP
    pop de
    pop hl

    inc a		; Returns 0 if A == -1 => a$ < b$

__FREE_STR: ; This exit point will test A' for bits 0 and 1
    ; If bit 0 is 1 => Free memory from HL pointer
    ; If bit 1 is 1 => Free memory from DE pointer
    ; Finally recovers A, to return the result
    PROC

    LOCAL __FREE_STR2
    LOCAL __FREE_END

    ex af, af'
    bit 0, a
    jr z, __FREE_STR2

    push af
    push de
    call __MEM_FREE
    pop de
    pop af

__FREE_STR2:
    bit 1, a
    jr z, __FREE_END

    ex de, hl
    call __MEM_FREE

__FREE_END:
    ex af, af'
    ret

    ENDP

    pop namespace
