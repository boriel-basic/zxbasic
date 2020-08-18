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

#ifdef __ENABLE_BREAK__
    ROM_SAVE EQU 0970h
#endif
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

    ld a, r
    push af
    call ROM_SAVE

    LOCAL NO_INT
    pop af
    jp po, NO_INT
    ei
NO_INT:
    ; Recovers ECHO_E since ROM SAVE changes it
    ld hl, 1821h
    ld (23682), hl
    pop ix
    ret

SAVE_STOP:
    pop ix
    jp __STOP

#ifndef __ENABLE_BREAK__
    LOCAL CHAN_OPEN
    LOCAL PO_MSG
    LOCAL WAIT_KEY
    LOCAL SA_BYTES
    LOCAL SA_CHK_BRK
    LOCAL SA_CONT

    CHAN_OPEN EQU 1601h
    PO_MSG EQU 0C0Ah
    WAIT_KEY EQU 15D4h
    SA_BYTES EQU 04C6h

ROM_SAVE:
    push hl
    ld a, 0FDh
    call CHAN_OPEN
    xor a
    ld de, 09A1h
    call PO_MSG
    set 5, (iy + 02h)
    call WAIT_KEY
    push ix
    ld de, 0011h
    xor a
    call SA_BYTES
    pop ix

    call SA_CHK_BRK
    jr c, SA_CONT
    pop ix
    ret

SA_CONT:
    ei
    ld b, 32h

LOCAL SA_1_SEC
SA_1_SEC:
    halt
    djnz SA_1_SEC

    ld e, (ix + 0Bh)
    ld d, (ix + 0Ch)
    ld a, 0FFh
    pop ix
    call SA_BYTES

SA_CHK_BRK:
    ld b, a
    ld a, (5C48h)
    and 38h
    rrca
    rrca
    rrca
    out (0FEh), a
    ld a, 7Fh
    in a, (0FEh)
    rra
    ld a, b
    ret

#endif
    
    ENDP
