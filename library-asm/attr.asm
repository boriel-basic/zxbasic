; Attribute routines
; vim:ts=4:et:sw:

#include once <sposn.asm>
#include once <error.asm>
#include once <in_screen.asm>
#include once <const.asm>
#include once <cls.asm>

__ATTR_ADDR:
    ; calc start address in DE (as (32 * d) + e)
    ; Contributed by Santiago Romero at http://www.speccy.org
    ld h, 0                     ;  7 T-States
    ld a, d                     ;  4 T-States
    add a, a     ; a * 2        ;  4 T-States
    add a, a     ; a * 4        ;  4 T-States
    ld l, a      ; HL = A * 4   ;  4 T-States

    add hl, hl   ; HL = A * 8   ; 15 T-States
    add hl, hl   ; HL = A * 16  ; 15 T-States
    add hl, hl   ; HL = A * 32  ; 15 T-States
    
    ld d, 18h ; DE = 6144 + E. Note: 6144 is the screen size (before attr zone)
    add hl, de

    ld de, (SCREEN_ADDR)    ; Adds the screen address
    add hl, de
    
    ; Return current screen address in HL
    ret


; Sets the attribute at a given screen coordinate (D, E).
; The attribute is taken from the ATTR_T memory variable
; Used by PRINT routines
SET_ATTR:

    ; Checks for valid coords
    call __IN_SCREEN
    ret nc

__SET_ATTR:
    ; Internal __FASTCALL__ Entry used by printing routines
    PROC 

    call __ATTR_ADDR
    ld de, (ATTR_T)    ; E = ATTR_T, D = MASK_T

    ld a, d
    and (hl)
    ld c, a    ; C = current screen color, masked

    ld a, d
    cpl        ; Negate mask
    and e    ; Mask current attributes
    or c    ; Mix them
    ld (hl), a ; Store result in screen
    
    ret
    
    ENDP


