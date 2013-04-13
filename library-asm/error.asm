; Simple error control routines
; vim:ts=4:et:

ERR_NR    EQU    23610    ; Error code system variable


; Error code definitions (as in ZX spectrum manual)

; Set error code with:
;    ld a, ERROR_CODE
;    ld (ERR_NR), a


ERROR_Ok                EQU    -1
ERROR_SubscriptWrong    EQU     2
ERROR_OutOfMemory       EQU     3
ERROR_OutOfScreen       EQU     4
ERROR_NumberTooBig      EQU     5
ERROR_InvalidArg        EQU     9
ERROR_IntOutOfRange     EQU    10
ERROR_InvalidFileName   EQU    14 
ERROR_InvalidColour     EQU    19
ERROR_BreakIntoProgram  EQU    20
ERROR_TapeLoadingErr    EQU    26


; Raises error using RST #8
__ERROR:
    ld (__ERROR_CODE), a
    rst 8
__ERROR_CODE:
    nop
    ret

; Sets the error system variable, but keeps running.
; Usually this instruction if followed by the END intermediate instruction.
__STOP:
    ld (ERR_NR), a
    ret
