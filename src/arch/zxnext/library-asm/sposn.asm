#include once <sysvars.asm>
#include once <attr.asm>

; Printing positioning library.
    push namespace core

; Loads into DE current ROW, COL print position from S_POSN mem var.
__LOAD_S_POSN:
    PROC

    ld de, (S_POSN)
    ld hl, SCR_SIZE
    or a
    sbc hl, de
    ex de, hl
    ret

    ENDP


; Saves ROW, COL from DE into S_POSN mem var.
__SAVE_S_POSN:
    PROC

    ld hl, SCR_SIZE
    or a
    sbc hl, de
    ld (S_POSN), hl ; saves it again

__SET_SCR_PTR:  ;; Fast
    push de
    call __ATTR_ADDR
    ld (DFCCL), hl
    pop de

    ld a, d
    ld c, a     ; Saves it for later

    and 0F8h    ; Masks 3 lower bit ; zy
    ld d, a

    ld a, c     ; Recovers it
    and 07h     ; MOD 7 ; y1
    rrca
    rrca
    rrca

    or e
    ld e, a

    ld hl, (SCREEN_ADDR)
    add hl, de    ; HL = Screen address + DE
    ld (DFCC), hl
    ret

    ENDP

    pop namespace
