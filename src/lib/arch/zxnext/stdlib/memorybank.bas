' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2023
' by Juan Segura (a.k.a. Duefectu) <http://zx.duefectucorp.com>
'
' Memory bank switch tools
' ----------------------------------------------------------------

#ifndef __LIBRARY_MEMORYBANK__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_MEMORYBANK__


' ----------------------------------------------------------------
' Place the bank indicated by bankNumber in the memory slot
' between $c000 and $ffff and updates the system variable BANKM.
' Only works on 128K and compatible models.
' Danger: If our program exceeds the address $c000 it may cause
' problems, use this function at your own risk.
' Parameters:
'     bankNumber (UByte): Bank number to place at $c000
' ----------------------------------------------------------------
SUB FASTCALL SetBank(bankNumber AS UByte)
ASM
        ; A = bankNumber to place at $c000
        ld d,a              ; D = bankNumber
        ld a,($5b5c)       ; Read BANKM system variable
        and %11111000       ; Reset bank bits
        or d                ; Set bank bits to bankNumber
        ld bc,$7ffd         ; Memory Bank control port
        di                  ; Disable interrupts
        ld ($5b5c),a         ; Update BANKM system variable
        out (c),a           ; Set the bank
        ei                  ; Enable interrupts
END ASM
END SUB


' ----------------------------------------------------------------
' Returns the memory bank located at $c000 based on the system
' variable BANKM.
' Only works on 128K and compatible models.
' Returns:
'     UByte: Bank number placed at $c000
' ----------------------------------------------------------------
FUNCTION FASTCALL GetBank() AS UByte
    RETURN PEEK $5b5c bAND %111
END FUNCTION


' ----------------------------------------------------------------
' Place the bank indicated by bankNumber in the memory slot
' between $c000 and $ffff, copy the contents to $8000-$bfff and
' restore the bank that was at $c000 before you started.
' Only works on 128K and compatible models.
' Danger: The contents of memory located between $8000 and $bfff
' are lost, and if our program exceeds the address $8000 it may
' cause problems, use this function at your own risk.
' Parameters:
'     bankNumber (UByte): Bank number to place at $8000
' ----------------------------------------------------------------
SUB SetCodeBank(bankNumber AS UByte)
    DIM b AS UByte

    b = GetBank()
    SetBank(bankNumber)

ASM
        ; Copy from $c000-$ffff to $8000-$bfff
        ld hl,$c000
        ld de,$8000
        ld bc,$4000
        ldir
END ASM

    SetBank(b)
END SUB

#endif
