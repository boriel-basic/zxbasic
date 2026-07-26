; CHR$(x, y, x) returns the string CHR$(x) + CHR$(y) + CHR$(z)
;
; zx81sd override: the only change from zx48k's version is TMP's storage
; address. The original uses the Spectrum ROM's DEST system variable
; (23629, safe scratch RAM on real hardware) to stash the return address
; while it calls __MEM_ALLOC -- on zx81sd that address falls inside the
; program's own compiled code (block 2, landed inside __DIVU32 in one
; observed build) instead of a real sysvar. CHR_SCRATCH (sysvars.asm) is
; a dedicated 2-byte scratch slot instead.

#include once <mem/alloc.asm>
#include once <sysvars.asm>

    push namespace core

CHR:	; Returns HL = Pointer to STRING (NULL if no memory)
    ; Requires alloc.asm for dynamic memory heap.
    ; Parameters: HL = Number of bytes to insert (already push onto the stack)
    ; STACK => parameters (16 bit, only the High byte is considered)
    ; Used registers A, A', BC, DE, HL, H'L'

    PROC

    LOCAL __POPOUT
    LOCAL TMP

TMP		EQU CHR_SCRATCH   ; zx81sd: dedicated scratch, not DEST

    ld a, h
    or l
    ret z	; If Number of parameters is ZERO, return NULL STRING

    ld b, h
    ld c, l

    pop hl	; Return address
    ld (TMP), hl

    push bc
    inc bc
    inc bc	; BC = BC + 2 => (2 bytes for the length number)
    call __MEM_ALLOC
    pop bc

    ld d, h
    ld e, l			; Saves HL in DE

    ld a, h
    or l
    jr z, __POPOUT	; No Memory, return

    ld (hl), c
    inc hl
    ld (hl), b
    inc hl

__POPOUT:	; Removes out of the stack every byte and return
    ; If Zero Flag is set, don't store bytes in memory
    ex af, af' ; Save Zero Flag

    ld a, b
    or c
    jr z, __CHR_END

    dec bc
    pop af 	   ; Next byte

    ex af, af' ; Recovers Zero flag
    jr z, __POPOUT

    ex af, af' ; Saves Zero flag
    ld (hl), a
    inc hl
    ex af, af' ; Recovers Zero Flag

    jp __POPOUT

__CHR_END:
    ld hl, (TMP)
    push hl		; Restores return addr
    ex de, hl	; Recovers original HL ptr
    ret

    ENDP

    pop namespace
