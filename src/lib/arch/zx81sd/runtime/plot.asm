; MIXED __FASTCALL__ / __CALLEE__ PLOT Function — ZX81 + SD81 Booster
; Adaptado de zx48k/runtime/plot.asm para sustituir las llamadas ROM
; por implementaciones propias (sin ROM Spectrum disponible).
;
; Cambios respecto al original zx48k:
;   - PIXEL_ADDR: llama a nuestra implementación en pixel_addr.asm
;   - COORDS: usa el valor de sysvars.asm ($8000+), no $5C7D
;   - PLOT_SUB: eliminado (el código propio no lo llama)

; Y in A (accumulator)
; X in top of the stack

#include once <error.asm>
#include once <in_screen.asm>
#include once <sysvars.asm>
#include once <set_pixel_addr_attr.asm>
#include once <pixel_addr.asm>

    push namespace core

PLOT:
    PROC

    LOCAL __PLOT_ERR
    LOCAL __PLOT_OVER1

    pop hl
    ex (sp), hl ; Callee

    ld b, a
    ld c, h

#ifdef SCREEN_Y_OFFSET
    ld a, SCREEN_Y_OFFSET
    add a, b
    ld b, a
#endif

#ifdef SCREEN_X_OFFSET
    ld a, SCREEN_X_OFFSET
    add a, c
    ld c, a
#endif

    ld a, 191
    cp b
    jr c, __PLOT_ERR ; jr is faster here (#1)

__PLOT:			; __FASTCALL__ entry (b, c) = pixel coords (y, x)
    ld (COORDS), bc	; Saves current point
    ld a, 191 ; Max y coord
    call PIXEL_ADDR
    res 6, h    ; no-op en SD81 (H siempre en $00-$17), mantiene compatibilidad
    ld bc, (SCREEN_ADDR)
    add hl, bc  ; Now current offset

    ld b, a
    inc b
    ld a, 0FEh
LOCAL __PLOT_LOOP
__PLOT_LOOP:
    rrca
    djnz __PLOT_LOOP

    ld b, a
    ld a, (P_FLAG)
    ld c, a
    ld a, (hl)
    bit 0, c        ; is it OVER 1
    jr nz, __PLOT_OVER1
    and b

__PLOT_OVER1:
    bit 2, c        ; is it inverse 1
    jr nz, __PLOT_END

    xor b
    cpl

LOCAL __PLOT_END
__PLOT_END:
    ld (hl), a
    jp SET_PIXEL_ADDR_ATTR

__PLOT_ERR:
    jp __OUT_OF_SCREEN_ERR ; Spent 3 bytes, but saves 3 T-States at (#1)

    ENDP

    pop namespace
