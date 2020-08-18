' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2019
' Contributed by Britlion and rearranged by John Mcgibbitts
' ----------------------------------------------------------------


#ifndef __LIBRARY_FASTPLOT__
REM Avoid recursive / multiple inclusion
#define __LIBRARY_FASTPLOT__

#pragma push(case_insensitive)
#pragma case_insensitive = True


' ----------------------------------------------------------------
' Plots a point at (x, y) in OVER 1 mode (XOR) with color as ATTR
' This routine is slightly faster than PLOT XOR 1 with ATTRs
' ----------------------------------------------------------------
SUB fastcall fastPlotXORAttr (x AS UBYTE, y AS UBYTE, color AS UBYTE)
ASM
    pop hl
    pop de
    ex (sp), hl
    ld c, h

    ld e, a
    ld a, 191
    sub d 
    ld d, a
    ret c

    AND a
    rra
    scf
    rra
    AND a
    rra
    XOR d
    AND 248
    XOR d
    ld h, a
    ld a, e
    rlca
    rlca
    rlca
    XOR d
    AND 199
    XOR d
    rlca
    rlca
    ld l, a

    ld a, e
    AND 7
    ld b, a
    inc b
    ld a, 254

plotPointXORAttr_loop:
    rrca
    djnz plotPointXORAttr_loop

    cpl
    xor (hl)
    ld (hl), a

plotPointXORAttr_end: ; ' Point plotted.
    ld a, h ; ' HL = addr of attr
    rrca
    rrca
    rrca
    and $03
    or $58
    ld h, a ; ' HL = addr of attr

    ld (hl),c
END ASM
END SUB


' ----------------------------------------------------------------
' Plots a point at (x, y) in OVER 1 mode (XOR) with color as ATTR
' This routine is slightly faster than PLOT XOR 1
' ----------------------------------------------------------------
SUB fastcall fastPlotXOR(x AS UBYTE, y AS UBYTE)
ASM
    pop hl
    ex (sp), hl

    ld e, a
    ld a, 191
    sub h
    ld d, a
    ret c

    AND a
    rra
    scf
    rra
    AND a
    rra
    XOR d
    AND 248
    XOR d
    ld h, a
    ld a, e
    rlca
    rlca
    rlca
    XOR d
    AND 199
    XOR d
    rlca
    rlca
    ld l, a

    ld a, e
    AND 7
    ld b, a
    inc b
    ld a, 254

plotPointXORAttr_loop:
    rrca
    djnz plotPointXORAttr_loop

    cpl
    xor (hl)
    ld (hl), a

END ASM
END SUB


#pragma pop(case_insensitive)

#endif
