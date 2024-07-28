#include once <cow/cow_.asm>

; String library


    push namespace core

__STRASSIGN: ; Performs a$ = b$ (HL = address of a$; DE = Address of b$)
    PROC

    push hl
    push de

    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a             ;  ld hl, (hl)
    call COW_MEM_FREE   ;  Frees old instance of Hl

    pop hl              ;  hl points to b$
    ld a, (hl)
    inc hl
    ld l, a             ;  ld hl, (hl). HL points to B$
    call COW_COPY_BLOCK ;  Obtains a copy of the block
    ex de, hl           ;  DE Points to new str
    pop hl              ;  Stores it in a$ PTR
    ld (hl), e
    inc hl
    ld (hl), d
    ret

    ENDP

    pop namespace

