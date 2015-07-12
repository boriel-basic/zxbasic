; Save code "XXX" at address YYY of length ZZZ
; Parameters in the stack are XXX (16 bit) address of string name
; (only first 12 chars will be taken into account)
; YYY and ZZZ are 16 bit on top of the stack.

#include once <error.asm>

SAVE_CODE:

    PROC
    
    LOCAL MEMBOT
    LOCAL SAVE_CONT
    LOCAL ROM_SAVE
    LOCAL __ERR_EMPTY
    LOCAL SAVE_STOP
    
    ROM_SAVE EQU 0970h    
    MEMBOT EQU 23698 ; Use the CALC mem to store header

    pop hl   ; Return address
    pop bc     ; data length in bytes
    pop de   ; address start
    ex (sp), hl ; CALLE => now hl = String

; This function will call the ROM SAVE CODE Routine
; Parameters in the stack are HL => String with SAVE name
; (only first 12 chars will be taken into account)
; DE = START address of CODE to save
; BC = Length of data in bytes

__SAVE_CODE: ; INLINE version
    ld a, b
    or c
    ret z    ; Return if block length == 0
    
    push ix
    ld a, h
    or l
    jr z, __ERR_EMPTY  ; Return if NULL STRING
    
    ld ix, MEMBOT
    ld (ix + 00), 3 ; CODE
    
    ld (ix + 11), c
    ld (ix + 12), b ; Store long in bytes
    ld (ix + 13), e
    ld (ix + 14), d ; Store address in bytes
    
    push hl
    ld bc, 9
    ld HL, MEMBOT + 1
    ld DE, MEMBOT + 2
    ld (hl), ' '
    ldir   ; Fill the filename with blanks
    pop hl    
    
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld a, b
    or c

__ERR_EMPTY:
    ld a, ERROR_InvalidFileName
    jr z, SAVE_STOP        ; Return if str len == 0
    
    ex de, hl  ; Saves HL in DE
    ld hl, 10
    or a
    sbc hl, bc  ; Test BC > 10?
    ex de, hl
    jr nc, SAVE_CONT ; Ok BC <= 10
    ld bc, 10 ; BC at most 10 chars
        
SAVE_CONT:
    ld de, MEMBOT + 1
    ldir     ; Copy String block NAME
    ld l, (ix + 13)
    ld h, (ix + 14)    ; Restores start of bytes    
    
    call ROM_SAVE
    ; Recovers ECHO_E since ROM SAVE changes it
    ld hl, 1821h
    ld (23682), hl
    pop ix
    ret

SAVE_STOP:
    pop ix
    jp __STOP
    
    ENDP
