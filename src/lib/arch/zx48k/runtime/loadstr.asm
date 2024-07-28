#include once <cow/cow_copy_block.asm>

; Loads a string (ptr) from HL
; and duplicates it on dynamic memory again
; Finally, it returns result pointer in HL

    push namespace core

__ILOADSTR:		; This is the indirect pointer entry HL = (HL)
    ld a, h
    or l
    ret z       ; Return if NULL. Nothing to copy
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a

__LOADSTR:		; __FASTCALL__ entry
    ld a, h
    or l
    ret z       ; Return if NULL. Nothing to copy

    jp COW_COPY_BLOCK

    pop namespace
