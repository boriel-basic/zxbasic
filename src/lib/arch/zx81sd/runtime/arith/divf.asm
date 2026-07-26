#include once <stackf.asm>
#include once <error.asm>
#include once <sysvars.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses C EDHL registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order BC DE HL (B not used).
;
; Uses CALLEE convention
; -------------------------------------------------------------
;
; zx81sd override: the only change from zx48k's version is where
; TMP/ERR_SP live. The original uses the Spectrum ROM's DEST (23629)
; and ERR_SP (23613) system variables to save/restore a stack recovery
; point around the division (a "longjmp" trick for divide-by-zero) --
; on zx81sd that mechanism never actually gets used for real recovery
; (__ERROR does DI+HALT directly, it doesn't restore SP from ERR_SP),
; but this code writes there on every division regardless of whether
; an error happens, and those addresses fall inside the program's own
; compiled code (block 2) instead of real sysvars. DIVF_SCRATCH
; (sysvars.asm) is dedicated scratch space instead -- same mechanism,
; just relocated.

    push namespace core

__DIVF:	; Division
    PROC
    LOCAL __DIVBYZERO
    LOCAL TMP, ERR_SP

TMP         EQU DIVF_SCRATCH       ; zx81sd: dedicated scratch, not DEST
ERR_SP      EQU DIVF_SCRATCH + 2   ; zx81sd: dedicated scratch, not ERR_SP

    call __FPSTACK_PUSH2

    ld hl, (ERR_SP)
    ld (TMP), hl
    ld hl, __DIVBYZERO
    push hl
    ld (ERR_SP), sp

    ; ------------- ROM DIV
    rst 28h
    defb 01h	; EXCHANGE
    defb 05h	; DIV
    defb 38h;   ; END CALC

    pop hl
    ld hl, (TMP)
    ld (ERR_SP), hl

    jp __FPSTACK_POP

__DIVBYZERO:
    ld hl, (TMP)
    ld (ERR_SP), hl

    ld a, ERROR_NumberTooBig
    ld (ERR_NR), a

    ; Returns 0 on DIV BY ZERO error
    xor a
    ld b, a
    ld c, a
    ld d, a
    ld e, a
    ret

    ENDP

    pop namespace
