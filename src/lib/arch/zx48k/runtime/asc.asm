; Returns the ascii code for the given str
#include once <cow/cow_mem_free.asm>

    push namespace core

__ASC:
    PROC
    LOCAL __ASC_END

    ld a, h
    or l
    ret z		; NULL? return

    ld c, (hl)
    inc hl
    ld b, (hl)

    ld a, b
    or c
    jr z, __ASC_END		; No length? return

    inc hl
    ld a, (hl)          ; ASCII code (to be returned)
    dec hl

__ASC_END:
    dec hl
    ex af, af'
    call COW_MEM_FREE	; Free memory if needed
    ex af, af'	; Recover result

    ret
    ENDP

    pop namespace
