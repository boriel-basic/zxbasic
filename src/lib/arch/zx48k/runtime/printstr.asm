#include once <print.asm>
#include once <sposn.asm>
#include once <attr.asm>
#include once <cow/cow_mem_free.asm>

; PRINT command routine
; Prints string pointed by HL

    push namespace core

PRINT_STR:
__PRINTSTR:		; __FASTCALL__ Entry to print_string
    PROC
    LOCAL __PRINT_STR_LOOP
    LOCAL __PRINT_STR_END

    ld a, h
    or l
    ret z	; Return if the pointer is NULL

    push hl

    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl	; BC = LEN(a$); HL = &a$

    ld a, b
    ld b, c
    ld c, a  ; swaps b, c
    or b
    jr z, __PRINT_STR_END 	; END if BC (counter = 0)
    inc c

__PRINT_STR_LOOP:
    ld a, (hl)
    call __PRINTCHAR
    inc hl
    djnz __PRINT_STR_LOOP
    dec c
    jr nz, __PRINT_STR_LOOP

__PRINT_STR_END:
    pop hl
    jp COW_MEM_FREE ; Frees str from heap and return from there

__PRINT_STR:
    ; Fastcall Entry
    ; It ONLY prints strings
    ; HL = String start
    ; BC = String length (Number of chars)
    push hl ; Push str address for later
    ld d, a ; Saves a FLAG
    jp __PRINT_STR_LOOP

    ENDP

    pop namespace
