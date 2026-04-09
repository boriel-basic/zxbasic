' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyright (C) 2026 Conrado Badenas <conbamen@gmail.com>
' Ideas taken from
'   https://github.com/boriel-basic/zxbasic/blob/main/src/lib/arch/zx48k/stdlib/memorybank.bas
'     by Juan Segura (a.k.a. Duefectu),
'   https://github.com/oisee/antique-toy/blob/main/chapters/ch16-sprites/draft.md
'     by Alice Vinogradova (a.k.a. oisee), and
'   https://youtu.be/nBHXtI1Y-xU?t=434 and https://youtu.be/-AUmmzDiGlE?t=434
'     by Benjamín (a.k.a. RetrobenSoft)
'
' Print Masked (AND+OR) Sprites, version 2026.04.05
' ----------------------------------------------------------------

#ifndef __CB_MASKEDSPRITES__

REM Avoid recursive / multiple inclusion

#define __CB_MASKEDSPRITES__

#include <memcopy.bas>
#include <scrbuffer.bas>


' ----------------------------------------------------------------
' MaskedSprites_OUT_7FFD is a MACRO of ASM code,
' which uses a hack to ensure a good reading of the IFF2 flip-flop.
' Hack was found thanks to Pedro Picapiedra aka ProgramadorHedonista,
' who pointed me to this line of the Z80 User Manual:
' "If an interrupt occurs during execution of this instruction
' [LD A,I or LD A,R], the Parity flag contains a 0."
' ----------------------------------------------------------------
#define MaskedSprites_OUT_7FFD                                          \
    ld c,a              ; save A in C                                   \
    ld a,i              ; IFF2=0/1=DI/EI is saved in PF=0/1=Odd/Even    \
    jp pe,1f            ; if PF=Even=1,  it is sure that IFF2=1=EI      \
    ld a,i              ; read IFF2 again to ensure that IFF2=0=DI      \
1:  ld a,c                                                              \
    ld bc,$7ffd         ; Memory Bank control port                      \
    di                  ; Disable interrupts (IFF1,2=0)                 \
    ld ($5b5c),a        ; Update BANKM system variable                  \
    out (c),a           ; Set the bank                                  \
    ret po              ; Return with DI if IFF2=0=DI at the beginning  \
    ei                  ; Return with EI if IFF2=1=EI at the beginning


' ----------------------------------------------------------------
' Set a RAM bank in addresses $c000-$ffff, update BANKM,
' and return with INTerrupts preserved (unchanged)
' Only works on 128K and compatible models.
' Parameters:
'     Ubyte: bank number 0,1,2,3,4,5,6,7
' Changes:
'     A, B, C
' Preserves:
'     D, E, H, L are not used
' ----------------------------------------------------------------
SUB FASTCALL SetBankPreservingINTs(bankNumber AS UByte)
ASM
    and 7               ; make sure bankNumber = 0,1,2,3,4,5,6,7
    ld c,a              ; C = A = bankNumber
    ld a,($5b5c)        ; Read BANKM system variable
    and %11111000       ; Reset bank bits
    or c                ; Set bank bits to bankNumber
    MaskedSprites_OUT_7FFD
END ASM
END SUB


' ----------------------------------------------------------------
' Get which RAM bank is set in addresses $c000-$ffff
' Only works on 128K and compatible models.
' Preserves:
'     B, C, D, E, H, L are not used
' Returns:
'     UByte: bank number 0,1,2,3,4,5,6,7
' ----------------------------------------------------------------
#define MaskedSprites_GETBANK                           \
    ld a,($5b5c)        ; Read BANKM system variable    \
    and 7               ; Obtain bank bits
FUNCTION FASTCALL GetBankPreservingRegs() AS UByte
ASM
    MaskedSprites_GETBANK
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Check whether memory paging works (128,+2,...) or not (16,48)
' Returns:
'     UByte: 1 if paging works, 0 if it does not
' ----------------------------------------------------------------
FUNCTION FASTCALL CheckMemoryPaging() AS UByte
    DIM b,i AS UByte
    DIM p AS UInteger
    CONST address AS UInteger = $fffe

    b = GetBankPreservingRegs()
    p = peek(UInteger, address)
    for i=0 to 7
        SetBankPreservingINTs(i)
        if p<>peek(UInteger, address) then  'there is another bank at address
            if i<>b then SetBankPreservingINTs(b)
            return 1
        end if
    next i
' Here, we are in an unpaged Spectrum (48), or maybe...
' ...all banks hold the same value p at address.

    poke UInteger address, p bXOR $5555 ' we change value at address in RAM7
    SetBankPreservingINTs(0)
    if p=peek(UInteger, address) then   ' value at address in RAM0 is as before
        SetBankPreservingINTs(7)
        poke UInteger address, p
        if 7<>b then SetBankPreservingINTs(b)
        return 1
    end if
    poke UInteger address, p ' memory paging does not work, we restore value at address
    return 0
ASM

END ASM
END FUNCTION


' ----------------------------------------------------------------
' Set the visible screen (either in bank5 or bank7)
' and updates the system variable BANKM.
' Only works on 128K and compatible models.
' Parameters:
'     Ubyte: bank number 5 or 7
' Preserves:
'     D, E, H, L are not used
' ----------------------------------------------------------------
SUB FASTCALL SetVisibleScreen(bankNumber AS UByte)
ASM
    ; A = bankNumber 5 or 7 with screen to be visible
    and %00000010       ; bit1 = 0/1 for bank5/7
    rla
    rla                 ; bit3 = 0/1 for bank5/7
    ld c,a
    ld a,($5b5c)        ; Read BANKM system variable
    and %11110111       ; Reset bit3
    or c                ; Set screen in bank5/7
    MaskedSprites_OUT_7FFD
END ASM
END SUB


' ----------------------------------------------------------------
' Returns the bank of visible screen (either 5 or 7)
' according to system variable BANKM.
' Only works on 128K and compatible models.
' Returns:
'     UByte: bank 5 or 7
' ----------------------------------------------------------------
FUNCTION FASTCALL GetVisibleScreen() AS UByte
ASM
    ld a,($5b5c)        ; Read BANKM system variable
    and %00001000       ; Get bit3 = 0/1 for bank5/7
    rra
    rra                 ; bit1 = 0/1 for bank5/7
    or  %00000101       ; A = 5/7 for bank5/7
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Toggles the visible screen (from 5 to 7, or from 7 to 5)
' and updates the system variable BANKM.
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB FASTCALL ToggleVisibleScreen()
    SetVisibleScreen(2 bXOR GetVisibleScreen() )
    '2 bXOR 5/7 = 7/5
END SUB


' ----------------------------------------------------------------
' Copy contents of screen5 to screen7 (display file + attribs)
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB FASTCALL CopyScreen5ToScreen7()
    DIM b AS UByte

    b = GetBankPreservingRegs()
    if b<>7 then SetBankPreservingINTs(7)
    MemCopy($4000,$c000,$1b00)
    if b<>7 then SetBankPreservingINTs(b)
END SUB


' ----------------------------------------------------------------
' Copy contents of screen7 to screen5 (display file + attribs)
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB FASTCALL CopyScreen7ToScreen5()
    DIM b AS UByte

    b = GetBankPreservingRegs()
    if b<>7 then SetBankPreservingINTs(7)
    MemCopy($c000,$4000,$1b00)
    if b<>7 then SetBankPreservingINTs(b)
END SUB


' ----------------------------------------------------------------
' Set ScreenBufferAddr and AttrBufferAddr to screen5
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB FASTCALL SetDrawingScreen5()
    SetScreenBufferAddr($4000)' ld (.core.SCREEN_ADDR),hl
      SetAttrBufferAddr($5800)' ld (.core.SCREEN_ATTR_ADDR),hl
END SUB


' ----------------------------------------------------------------
' Put screen7 at $c000 (in case it is not), and
' Set ScreenBufferAddr and AttrBufferAddr to screen7
' Only works on 128K and compatible models.
' Returns:
'     Bank7 is set at $c000, old bank is removed
'     UByte: bank that was at $c000 (to restore it manually IYW)
' ----------------------------------------------------------------
FUNCTION FASTCALL SetDrawingScreen7() AS UByte
    DIM b AS UByte

    b = GetBankPreservingRegs()
    if b<>7 then SetBankPreservingINTs(7)
    SetScreenBufferAddr($c000)' ld (.core.SCREEN_ADDR),hl
      SetAttrBufferAddr($d800)' ld (.core.SCREEN_ATTR_ADDR),hl
    RETURN b
END FUNCTION


' ----------------------------------------------------------------
' Toggle ScreenBufferAddr and AttrBufferAddr between screen5,7
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB FASTCALL ToggleDrawingScreen()
    SetScreenBufferAddr($8000 bXOR GetScreenBufferAddr() )
      SetAttrBufferAddr($8000 bXOR   GetAttrBufferAddr() )
    '$8000 bXOR $4000/$c000 = $c000/$4000
    '$8000 bXOR $5800/$d800 = $d800/$5800
END SUB


' ----------------------------------------------------------------
' MaskedSpritesBackgroundSet = 0 or 1 is the Set of Backgrounds
'
' MaskedSpritesBackground(i) is the address where Background i begins
'
' NumberofMaskedSprites is a MACRO that should be #define-d
' before #include-ing this file
'
' MaskedSprites_USE_STACK_TRANSFER is a MACRO that should be #define-d
' if you want this library to use Stack PUSH+POP instructions to speed-up
' transfer of information between different parts of the RAM
' (this library will disable interrupts before using Stack Transfer)
'
' ChangeMaskedSpritesBackgroundSet() changes the Set of Backgrounds
' Returns:
'     Byte: new value of MaskedSpritesBackgroundSet (IYW to use it)
' ----------------------------------------------------------------
dim MaskedSpritesBackgroundSet AS UByte = 0

#define MaskedSpritesBackground(i) ( $db00+48*CAST(UInteger,i)+48*CAST(UInteger,NumberofMaskedSprites)*MaskedSpritesBackgroundSet )

FUNCTION FASTCALL ChangeMaskedSpritesBackgroundSet() AS UByte
    MaskedSpritesBackgroundSet = MaskedSpritesBackgroundSet bXOR 1
    RETURN MaskedSpritesBackgroundSet
END FUNCTION


' ----------------------------------------------------------------
' MaskedSprites_NEXT_ROW is a MACRO of ASM code, based on code from
' https://zonadepruebas.com/viewtopic.php?f=15&t=8372&start=40#p81507
' and found by Joaquin Ferrero
' ----------------------------------------------------------------
#define MaskedSprites_NEXT_ROW                                          \
    ld a,e  ; 4   A = E                                                 \
    sub 224 ; 7   A = E + 32 (SUB 224 is similar to +32)                \
            ;     CF = 0/1 iff E >=/< 224 iff a third is/isn't crossed  \
    ld e,a  ; 4                                                         \
    sbc a,a ; 4   A = 0/255                                             \
    and 248 ; 7   A = 0/248 (248 = -8)                                  \
    add a,d ; 4   A = D/D-8 iff a third is/isn't crossed                \
    ld d,a  ; 4 += 34 Ts


' ----------------------------------------------------------------
' Save background and Draw sprite in screen
' Parameters:
'     UByte:    X coordinate (0:left to 240:right)
'     UByte:    Y coordinate (0:up   to 176:down)
'     UInteger: Address where background will be saved
'     UInteger: Address where sprite image begins
' ----------------------------------------------------------------
SUB FASTCALL SaveBackgroundAndDrawSprite(X AS UByte, Y AS UByte, backgroundAddr AS UInteger, spriteImageAddr AS UInteger)
ASM
    PROC
    LOCAL shiftright, shiftleft, noshift
    LOCAL loopSR, loopSL, loopNS, loopR, loopL, branchSR, branchSL, branchNS
    ; A = X
    pop de              ; returnAddr
    exx
    pop bc              ; B = Y
    ld c,a              ; C = X
; BEGIN code from https://skoolkid.github.io/rom/asm/22AA.html
    rlca
    rlca
    rlca                ; A = %c4c3c2c1c0c7c6c5
    xor b
    and %11000111
    xor b               ; A = %c4c3b5b4b3c7c6c5
    rlca
    rlca
    ld e,a              ; E = %b5b4b3c7c6c5c4c3
    ld a,b
    and %11111000
    rra
    rra
    rra                 ; A = %.0.0.0b7b6b5b4b3
    xor b
    and %11111000
    xor b
    ld d,a              ; D = %.0.0.0b7b6b2b1b0
; END code from https://skoolkid.github.io/rom/asm/22AA.html
    ld hl,(.core.SCREEN_ADDR)
    add hl,de
    ex de,hl            ; DE = screenAddr where drawing will start
    ld a,c;             ; A = X
    and 7
    jr z,noshift        ; jump if X is a multiple of 8 (unlikely)
                        ; continue if sprite must be shifted
    cp 4                ; is >= 4 ?
    jp nc,shiftleft     ; shift left  if X MOD 8 = 4,5,6,7
                        ; shift right if X MOD 8 = 1,2,3
shiftright:
    pop bc              ; backgroundAddr
    exx
    pop hl              ; spriteImageAddr
    push de             ; returnAddr
    push ix
    ld ixh,16           ; 16 scanlines
    ld ixl,a            ; IXl = X MOD 8 = 1,2,3,4
loopSR:
        ld a,(hl)       ; mask1
        inc hl
        ld c,(hl)       ; graph1
        inc hl
        ld d,(hl)       ; mask2
        inc hl
        ld e,(hl)       ; graph2
        inc hl
        push hl         ; spriteImageAddr

        ld hl,$FF00     ; H = 255 , L = 0
        ld b,ixl
loopR:
            scf         ; 4
            rra         ; 4; SCF + RRA injects a 1 in bit7 of A
            rr d        ; 8
            rr h        ; 8
            srl c       ; 8; ShiftRightLogical injects a 0 in bit7 of C
            rr e        ; 8
            rr l        ; 8
            djnz loopR  ; 4+4+8+8+8+8+8 = 48 Ts
        ld b,a
        push hl         ; H,L = mask,graph 3rd byte
        push de         ; D,E = mask,graph 2nd byte
        push bc         ; B,C = mask,graph 1st byte
        exx

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 1st byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 2nd byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 3rd byte done
        dec e
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchSR   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        exx
        pop hl          ; spriteImageAddr
        dec ixh
        jp nz,loopSR
    pop ix
    ret
branchSR:
        MaskedSprites_NEXT_ROW
        exx
        pop hl          ; spriteImageAddr
        dec ixh
        jp nz,loopSR
    pop ix
    ret

noshift:
    pop bc              ; backgroundAddr
    pop hl              ; spriteImageAddr
    exx
    push de             ; returnAddr
    exx
    push ix
    ld ixh,16           ; 16 scanlines
loopNS:
        ld a,(de)       ; screen
        ld (bc),a;      ; save
        inc bc
        and (hl);       ; mask
        inc hl
        or (hl)         ; graph
        inc hl
        ld (de),a       ; 1st byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        and (hl);       ; mask
        inc hl
        or (hl)         ; graph
        inc hl
        ld (de),a       ; 2nd byte done
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchNS   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        dec ixh
        jp nz,loopNS
    pop ix
    ret
branchNS:
        MaskedSprites_NEXT_ROW
        dec ixh
        jp nz,loopNS
    pop ix
    ret

shiftleft:
    pop bc              ; backgroundAddr
    exx
    pop hl              ; spriteImageAddr
    push de             ; returnAddr
    push ix
    ld ixh,16           ; 16 scanlines
    sub 8
    neg                 ; A = 8 - oldA
    ld ixl,a            ; IXl = 8 - (X MOD 8) = 8 - 4,5,6,7 = 4,3,2,1
loopSL:
        ld a,(hl)       ; mask1
        inc hl
        ld c,(hl)       ; graph1
        inc hl
        ld d,(hl)       ; mask2
        inc hl
        ld e,(hl)       ; graph2
        inc hl
        push hl         ; spriteImageAddr

        ld hl,$FF00     ; H = 255 , L = 0
        ld b,ixl
loopL:
            sll d       ; 8; ShiftLeftLogical injects a 1 in bit0 of D
            rla         ; 4
            rl h        ; 8
            sla e       ; 8; ShiftLeftArithmetic injects a 0 in bit0 of E
            rl c        ; 8
            rl l        ; 8
            djnz loopL  ; 8+4+8+8+8+8 = 44 Ts
        ld b,a
        push de         ; D,E = mask,graph 3rd byte
        push bc         ; B,D = mask,graph 2nd byte
        push hl         ; H,L = mask,graph 1st byte
        exx

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 1st byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 2nd byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
        pop hl
        and h           ; mask
        or l            ; graph
        ld (de),a       ; 3rd byte done
        dec e
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchSL   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        exx
        pop hl          ; spriteImageAddr
        dec ixh
        jp nz,loopSL
    pop ix
    ret
branchSL:
        MaskedSprites_NEXT_ROW
        exx
        pop hl          ; spriteImageAddr
        dec ixh
        jp nz,loopSL
    pop ix
    ret
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' Restore background in screen
' Parameters:
'     UByte:    X coordinate (0:left to 240:right)
'     UByte:    Y coordinate (0:up   to 176:down)
'     UInteger: Address where saved background begins
' ----------------------------------------------------------------
SUB FASTCALL RestoreBackground(X AS UByte, Y AS UByte, backgroundAddr AS UInteger)
ASM
    PROC
    LOCAL loop2b, loop3b, branch2b, branch3b
    ; A = X
    pop de              ; returnAddr
    exx
    pop bc              ; B = Y
    ld c,a              ; C = X
; BEGIN code from https://skoolkid.github.io/rom/asm/22AA.html
    rlca
    rlca
    rlca                ; A = %c4c3c2c1c0c7c6c5
    xor b
    and %11000111
    xor b               ; A = %c4c3b5b4b3c7c6c5
    rlca
    rlca
    ld e,a              ; E = %b5b4b3c7c6c5c4c3
    ld a,b
    and %11111000
    rra
    rra
    rra                 ; A = %.0.0.0b7b6b5b4b3
    xor b
    and %11111000
    xor b
    ld d,a              ; D = %.0.0.0b7b6b2b1b0
; END code from https://skoolkid.github.io/rom/asm/22AA.html
    ld hl,(.core.SCREEN_ADDR)
    add hl,de
    ex de,hl            ; DE = screenAddr where restoring will start
    pop hl              ; backgroundAddr
    exx
    push de             ; returnAddr
    exx
    ld a,c;             ; A = X
    ld bc,$10FF         ; B = 16, C = 255 (up to 255 LDIs do not change B)
    and 7
    jr z,loop2b         ; jump if X is a multiple of 8 (unlikely)
                        ; continue if restoring 3 bytes per scanline
; 3bytes per scanline
loop3b:
        ldi             ; 16 Ts vs 7+7+6+4=24 Ts
        ldi
        ldi             ; 3 bytes background restored to screen
        dec de          ; last LDI could have increased D if initially E=253...
        dec e           ; ...so DEC DE restores D in that case
        dec e

        inc d
        ld a,d
        and 7
        jr z,branch3b   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        djnz loop3b
    ret
branch3b:
        MaskedSprites_NEXT_ROW
        djnz loop3b
    ret
; 2bytes per scanline
loop2b:
        ldi             ; 16 Ts vs 7+7+6+4=24 Ts
        ldi             ; 2 bytes background restored to screen
        dec de          ; last LDI could have increased D if initially E=254...
        dec e           ; ...so DEC DE restores D in that case

        inc d
        ld a,d
        and 7
        jr z,branch2b   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        djnz loop2b
    ret
branch2b:
        MaskedSprites_NEXT_ROW
        djnz loop2b
    ret
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' Structure of the Masked Sprites FileSystem (MSFS):
'
' MSFS consists of many blocks of 96 bytes
' MSFS starts at address stored in MaskedSpritesFileSystemStart, e.g., 56736
' MSFS length is a multiple of 96 bytes, e.g., 8736 = 91*96 bytes
'      With that length, MSFS ranges from 56736 to 65471
' MSFS stores Images (mask+graph) of Masked Sprites
' Blocks used are marked in the FSB (https://en.wikipedia.org/wiki/Free-space_bitmap)
'
' First block of the MSFS (superblock, block number = 0)
' start+0     DEFB number of blocks in MSFS = bits of the FSB, e.g., 91
' start+1     DEFB number of bytes of the FSB, e.g., 12 (91/8 = 11.4)
' start+2-13  DEFS 12 is the FSB (12 bytes = 96 bits is enough for 91 blocks)
' start+14-15 unused
'
' Block of an unshifted image (block number n = 0,...,90)
' start+n*96    \
' ...           | 16 bytes unused for n>0, superblock for n=0
' start+n*96+15 /
' start+n*96+16-17 DEFW start+n*96+32 = start of unshifted image
' start+n*96+18-19 DEFW address of block for image shifted 1 pixel, or 0 if not used
' start+n*96+20-21 DEFW address of block for image shifted 2 pixels, or 0 if not used
' ...
' start+n*96+30-31 DEFW address of block for image shifted 7 pixels, or 0 if not used
' start+n*96+32-95 DEFS 64 the unshifted image (mask+graph)
'
' Block number 0 (n=0) is special because it contains
'   16 bytes for the superblock (including 2 unused bytes) +
'   16 bytes for addressing unshifted and shifted versions of the first image +
'   64 bytes for the first unshifted image
'
' Block of a shifted image (block number m = 1,...,90, note m>0)
' start+m*96+0  DEFS 96 the shifted image (mask+graph)
' ----------------------------------------------------------------
dim MaskedSpritesFileSystemStart AS UInteger = 0
' ----------------------------------------------------------------
'   MaskedSpritesFileSystemStart = address where Masked Sprites FileSystem starts
'
' InitMaskedSpritesFileSystem() inits the MSFS
' Returns:
'     UInteger: value of MaskedSpritesFileSystemStart (IYW to use it)
' ----------------------------------------------------------------
FUNCTION FASTCALL InitMaskedSpritesFileSystem() AS UInteger
    DIM b,c AS UByte
    DIM l AS UInteger

    c = CheckMemoryPaging()
    if c then
        b = GetBankPreservingRegs()
        if b<>7 then SetBankPreservingINTs(7)
        MaskedSpritesFileSystemStart = $db00+96*NumberofMaskedSprites
    else
        MaskedSpritesFileSystemStart = $db00+48*NumberofMaskedSprites
    end if
    l = -MaskedSpritesFileSystemStart
    l = Int(l/96)
    poke MaskedSpritesFileSystemStart,  l ' MSFS blocks = FSB bits
    if l=0 then STOP
    l = 1+Int((l-1)/8)
    poke MaskedSpritesFileSystemStart+1,l ' FSB bytes
    if c then
        if b<>7 then SetBankPreservingINTs(b)
    end if
    return MaskedSpritesFileSystemStart

' Now, some assembly routines needed for next SUB/FUNCTIONs
ASM
; ----------------------------------------------------------------
; Find memory addres in MSFS for the start of a block
; Parameters:
;     L = blocknumber = n = 0,1,2,... (probably less than 200)
; Preserves:
;     A, B, C are not used
; Returns:
;     HL = start+n*96
;     DE = start
; ----------------------------------------------------------------
FindMemoryAdressForBlockInMSFS:
    PROC
    ld h,0
    ld d,h
    ld e,l              ; HL = DE = n = blocknumber
    add hl,de
    add hl,de           ; HL = DE*3
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl           ; HL = DE*3*(2^5) = DE*96
    ld de,(_MaskedSpritesFileSystemStart)
    add hl,de;          ; HL = start+n*96
    ret
    ENDP

; ----------------------------------------------------------------
; Find First Unused Block in MSFS and (optionally) Book it
; Parameters:
;     CarryFlag = 0/1 don't/do Book it
; Preserves:
;     C is not used
; Returns:
;     CarryFlag = 0        if found, 1 if not found
;     A = FirstUnusedBlock if found
;     HL = start+A*96      if found
; ----------------------------------------------------------------
FindFirstUnusedBlockInMSFS:
    PROC
    LOCAL loop1, loop2, full, found, loop3, compute
    ex af,af'           ; saves CarryFlag
    ld hl,(_MaskedSpritesFileSystemStart)
    ld d,(hl)
    ld e,d              ; D = E = number of bits in the FSB = N
    inc hl
    inc hl              ; HL points to the first byte in the FSB
loop1:
        ld a,(hl)
        ld b,8
loop2:
            rrca
            jr nc,found
            dec e
            jr z,full
            djnz loop2
        inc hl
        jp loop1
full:                   ; E = 0
    scf                 ; CarryFlag=1 = ERROR
    ret
found:                  ; E = N,N-1,N-2,...,1
    ex af,af'
    jr nc,compute
    ex af,af'
    rlca                ; undo last RRCA
    or 1                ; mark this block as used
loop3:
        rrca            ; finish the 8-bit rotation to...
        djnz loop3      ; leave bits where they were
    ld (hl),a           ; effective booking
compute:
    ld a,d              ; A = N
    sub e               ; A = 0,1,2,...,N-1 = blocknumber
    ld l,a
    call FindMemoryAdressForBlockInMSFS
    and a               ; CarryFlag=0 = OK
    ret                 ; A = blocknumber, HL = start+A*96
    ENDP
END ASM

END FUNCTION


' ----------------------------------------------------------------
' Get Number of Free Blocks in MSFS
' Returns:
'     UByte: number of free blocks in MSFS
' ----------------------------------------------------------------
FUNCTION FASTCALL GetNumberofFreeBlocksInMSFS() AS UByte
ASM
    PROC
    LOCAL loop1, loop2, exit
    call _GetBankPreservingRegs
    cp 7                ; ZeroFlag=0 (NZ) iff _GetBankPreservingRegs returns A<>7
    push af             ; ZF and original RAM bank when FUNCTION was called
     ld a,7
     call nz,_SetBankPreservingINTs ; set RAM7 if _GetBankPreservingRegs returns A<>7
     xor a              ; A = 0 = number of reset bits in the FSB
     ld hl,(_MaskedSpritesFileSystemStart)
     ld d,(hl)          ; D = number of bits in the FSB = N
     ld e,a             ; E = 0 always
     inc hl
     inc hl             ; HL points to the first byte in the FSB
loop1:
        ld c,(hl)
        ld b,8
loop2:
            rr c
            ccf         ; CarryFlag = 0/1 = bit in the FSB is set/reset
            adc a,e     ; A += CarryFlag = number of reset bits in the FSB
            dec d
            jr z,exit   ; return A if all bits in FSB have been checked
            djnz loop2
        inc hl
        jr loop1
exit:
     ex af,af'          ; A' = number of free blocks in MSFS
    pop af              ; ZF and original RAM bank when FUNCTION was called
    call nz,_SetBankPreservingINTs
    ex af,af'           ; A = number of free blocks in MSFS
    ret
    ENDP
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Register spriteImage in MSFS
' Parameters:
'     UInteger: address where spriteImage begins
' Returns:
'     UInteger: registry number in the MSFS = start+n*96+16 if OK
'               0                                           if not OK
' ----------------------------------------------------------------
FUNCTION FASTCALL RegisterSpriteImageInMSFS(spriteImageAddr AS UInteger) AS UInteger
ASM
    PROC
    LOCAL full, exit
    call _GetBankPreservingRegs
    cp 7                ; ZeroFlag=0 (NZ) iff _GetBankPreservingRegs returns A<>7
    push af             ; ZF and original RAM bank when FUNCTION was called
     push hl            ; spriteImageAddr
      ld a,7
      call nz,_SetBankPreservingINTs  ; set RAM7 if it was not set
      scf
      call FindFirstUnusedBlockInMSFS ; and book it (SCF)
      jr c,full
      ld bc,16
      add hl,bc
      push hl           ; HL = start+A*96+16
       ld d,h
       ld e,l
       inc de           ; DE = start+A*96+17
       dec bc           ; BC = 15
       ld (hl),0
       ldir             ; reset RAM from start+A*96+16 to start+A*96+31 (incl.)
      pop hl            ; HL = start+A*96+16
      ld b,h
      ld c,l            ; BC = start+A*96+16
      ld (hl),e         ; DE = start+A*96+32 (after last LDIR)
      inc hl
      ld (hl),d         ; start+A*96+16-17 DEFW start+A*96+32
     pop hl             ; spriteImageAddr
     push bc            ; BC = start+A*96+16
      ld bc,64
      ldir              ; transfer from spriteImageAddr to start+A*96+32
     pop hl             ; HL = start+A*96+16
exit:
    pop af              ; ZF and original RAM bank when FUNCTION was called
    call nz,_SetBankPreservingINTs
    ret
full:
     pop hl             ; spriteImageAddr
     ld hl,0
     jr exit
    ENDP
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Register spriteGraph and spriteMask in MSFS
' (useful when different Graphs share the same Mask)
'
' Data in spriteGraph and spriteMask MUST be in "putchars format"
'
' Parameters:
'     UInteger: address where spriteGraph begins
'     UInteger: address where spriteMask  begins
' Returns:
'     UInteger: registry number in the MSFS = start+n*96+16 if OK
'               0                                           if not OK
' ----------------------------------------------------------------
FUNCTION FASTCALL RegisterSpriteGraphAndMaskInMSFS(spriteGraphAddr AS UInteger,spriteMaskAddr AS UInteger) AS UInteger
ASM
    PROC
    LOCAL full, exit, loop1, loop2
    pop de              ; returnAddr
    pop bc              ; spriteMaskAddr
    push de             ; returnAddr
; stack is empty. Now we will push data to be preserved
    exx                 ; HL' = spriteGraphAddr, BC' = spriteMaskAddr
    call _GetBankPreservingRegs
    cp 7                ; ZeroFlag=0 (NZ) iff _GetBankPreservingRegs returns A<>7
    push af             ; ZF and original RAM bank when FUNCTION was called
     ld a,7
     call nz,_SetBankPreservingINTs  ; set RAM7 if it was not set
     scf
     call FindFirstUnusedBlockInMSFS ; and book it (SCF)
     jr c,full
     ld bc,16
     add hl,bc
     push hl            ; HL = start+A*96+16
      ld d,h
      ld e,l
      inc de            ; DE = start+A*96+17
      dec bc            ; BC = 15
      ld (hl),0
      ldir              ; reset RAM from start+A*96+16 to start+A*96+31 (incl.)
     pop hl             ; HL = start+A*96+16
     ld (hl),e          ; DE = start+A*96+32 (after last LDIR)
     inc hl
     ld (hl),d          ; start+A*96+16-17 DEFW start+A*96+32
     dec hl
     push hl            ; return value HL = start+A*96+16
      push de           ; DE = start+A*96+32 DEFS 64 the unshifted image (mask+graph)
       exx              ; HL = spriteGraphAddr, BC = spriteMaskAddr
      pop de            ; DE = DEFS 64 the unshifted image (mask+graph)
      push ix
       push de          ; DE = start+A*96+32
        ld ixl,16
loop1:
            ld a,(bc)   ; mask
            ld (de),a
            inc bc
            inc de
            ld a,(hl)   ; graph
            ld (de),a
            inc hl
            inc de
            inc de
            inc de
            dec ixl
            jp nz,loop1
       pop de           ; DE = start+A*96+32
       inc de
       inc de           ; DE = start+A*96+32 +2
       ld ixl,16
loop2:
            ld a,(bc)   ; mask
            ld (de),a
            inc bc
            inc de
            ld a,(hl)   ; graph
            ld (de),a
            inc hl
            inc de
            inc de
            inc de
            dec ixl
            jp nz,loop2
      pop ix
     pop hl             ; return value HL = start+A*96+16
exit:
    pop af              ; ZF and original RAM bank when FUNCTION was called
    call nz,_SetBankPreservingINTs
    ret
full:
     ld hl,0
     jr exit
    ENDP
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Save background and Draw sprite registered in the MSFS
' Parameters:
'     UByte:    X coordinate (0:left to 240:right)
'     UByte:    Y coordinate (0:up   to 176:down)
'     UInteger: address where background will be saved
'     UInteger: registry number in the MSFS for the spriteImage
' ----------------------------------------------------------------
SUB FASTCALL SaveBackgroundAndDrawSpriteRegisteredInMSFS(X AS UByte, Y AS UByte, backgroundAddr AS UInteger, spriteImageReg AS UInteger)
ASM
    PROC
    LOCAL full, makeShiftedImage, loopMSI, loopMSI1
    LOCAL useShiftedImage, loopUSI, branchUSI, exitUSI
    LOCAL noshift, loopNS, branchNS, exitNS
    ; A = X
    pop de              ; returnAddr
    exx
    pop bc              ; B = Y
    ld c,a              ; C = X
; BEGIN code from https://skoolkid.github.io/rom/asm/22AA.html
    rlca
    rlca
    rlca                ; A = %c4c3c2c1c0c7c6c5
    xor b
    and %11000111
    xor b               ; A = %c4c3b5b4b3c7c6c5
    rlca
    rlca
    ld e,a              ; E = %b5b4b3c7c6c5c4c3
    ld a,b
    and %11111000
    rra
    rra
    rra                 ; A = %.0.0.0b7b6b5b4b3
    xor b
    and %11111000
    xor b
    ld d,a              ; D = %.0.0.0b7b6b2b1b0
; END code from https://skoolkid.github.io/rom/asm/22AA.html
    ld hl,(.core.SCREEN_ADDR)
    add hl,de
    ex de,hl            ; DE = screenAddr where drawing will start
    ld a,c;             ; A = X, keep it secret, keep it safe
    pop bc              ; BC = backgroundAddr
    pop hl              ; HL = spriteImageReg
    exx
    push de             ; returnAddr
    exx
; stack is empty. Now we will push data to be preserved
    push ix
    ld ixh,16           ; 16 scanlines
    and 7
    jr z,noshift        ; jump if X is a multiple of 8 (unlikely)
    push de             ; DE = screenAddr where drawing will start
    push bc             ; BC = backgroundAddr
     ld b,0
     ld c,a             ; BC = A = 1,2,3,4,5,6,7
     add hl,bc
     add hl,bc          ; HL = start+n*96+16+C*2 DEFW address of block for image shifted C pixels, or 0 if not used
     ld e,(hl)
     inc hl
     ld d,(hl)          ; DE = address for image shifted C pixels, or 0 if not used
     ld a,d
     or e
     jp z,makeShiftedImage
;UseShiftedImage (USI)
useShiftedImage:
     ex de,hl           ; HL = address for image shifted C pixels
    pop bc              ; BC = backgroundAddr
    pop de              ; DE = screenAddr where drawing will start
#ifdef MaskedSprites_USE_STACK_TRANSFER
    ld a,i              ; IFF2=0/1=DI/EI is saved in PF=0/1=Odd/Even
    jp pe,1f            ; if PF=Even=1,  it is sure that IFF2=1=EI
    ld a,i              ; read IFF2 again to ensure that IFF2=0=DI
1:  ex af,af'
    di
    ld (exitUSI+1),sp
    ld sp,hl
#endif
loopUSI:
        ld a,(de)       ; screen
        ld (bc),a;      ; save
        inc bc
#ifdef MaskedSprites_USE_STACK_TRANSFER
        pop hl
        and l           ; mask
        or h            ; graph
#else
        and (hl);       ; mask
        inc l
        or (hl)         ; graph
        inc hl
#endif
        ld (de),a       ; 1st byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a;      ; save
        inc bc
#ifdef MaskedSprites_USE_STACK_TRANSFER
        pop hl
        and l           ; mask
        or h            ; graph
#else
        and (hl);       ; mask
        inc l
        or (hl)         ; graph
        inc hl
#endif
        ld (de),a       ; 2nd byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a;      ; save
        inc bc
#ifdef MaskedSprites_USE_STACK_TRANSFER
        pop hl
        and l           ; mask
        or h            ; graph
#else
        and (hl);       ; mask
        inc l
        or (hl)         ; graph
        inc hl
#endif
        ld (de),a       ; 3rd byte done
        dec e
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchUSI  ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        dec ixh
        jp nz,loopUSI
exitUSI:
#ifdef MaskedSprites_USE_STACK_TRANSFER
    ld sp,$1234
    pop ix
    ex af,af'
    ret po              ; Return with DI if IFF2=0=DI at the beginning
    ei                  ; Return with EI if IFF2=1=EI at the beginning
    ret    
#else
    pop ix
    ret
#endif
branchUSI:
        MaskedSprites_NEXT_ROW
        dec ixh
        jp nz,loopUSI
#ifdef MaskedSprites_USE_STACK_TRANSFER
    jp exitUSI
#else
    pop ix
    ret
#endif
;NoShift (NS)
noshift:
    ld a,(hl)           ; HL = spriteImageReg
    inc hl
    ld h,(hl)
    ld l,a              ; HL = start of unshifted image
#ifdef MaskedSprites_USE_STACK_TRANSFER
    ld a,i              ; IFF2=0/1=DI/EI is saved in PF=0/1=Odd/Even
    jp pe,1f            ; if PF=Even=1,  it is sure that IFF2=1=EI
    ld a,i              ; read IFF2 again to ensure that IFF2=0=DI
1:  ex af,af'
    di
    ld (exitNS+1),sp
    ld sp,hl
#endif
loopNS:
        ld a,(de)       ; screen
        ld (bc),a;      ; save
        inc bc
#ifdef MaskedSprites_USE_STACK_TRANSFER
        pop hl
        and l           ; mask
        or h            ; graph
#else
        and (hl);       ; mask
        inc l
        or (hl)         ; graph
        inc hl
#endif
        ld (de),a       ; 1st byte done
        inc e

        ld a,(de)       ; screen
        ld (bc),a       ; save
        inc bc
#ifdef MaskedSprites_USE_STACK_TRANSFER
        pop hl
        and l           ; mask
        or h            ; graph
#else
        and (hl);       ; mask
        inc l
        or (hl)         ; graph
        inc hl
#endif
        ld (de),a       ; 2nd byte done
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchNS   ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        dec ixh
        jp nz,loopNS
exitNS:
#ifdef MaskedSprites_USE_STACK_TRANSFER
    ld sp,$1234
    pop ix
    ex af,af'
    ret po              ; Return with DI if IFF2=0=DI at the beginning
    ei                  ; Return with EI if IFF2=1=EI at the beginning
    ret    
#else
    pop ix
    ret
#endif
branchNS:
        MaskedSprites_NEXT_ROW
        dec ixh
        jp nz,loopNS
#ifdef MaskedSprites_USE_STACK_TRANSFER
    jp exitNS
#else
    pop ix
    ret
#endif
;MakeShiftedImage (MSI)
makeShiftedImage:
     ld a,8
     sub c              ; C = X MOD 8 = 1,2,3,4,5,6,7 to the right
     ld ixl,a           ; IXl = 8 - C = 7,6,5,4,3,2,1 to the left
     push hl            ; HL = start+n*96+16+C*2 + 1
      scf
      call FindFirstUnusedBlockInMSFS ; and book it (SCF)
      jr c,full
      ex de,hl          ; DE = start+m*96 = address for the shiftedimage-to-be
     pop hl             ; HL = start+n*96+16+C*2 + 1
     ld (hl),d
     dec hl
     ld (hl),e;         ; HL = start+n*96+16+C*2 DEFW address for the shifted image
     ld b,0
     sbc hl,bc
     sbc hl,bc
     ld a,(hl)          ; HL = spriteImageReg
     inc hl
     ld h,(hl)
     ld l,a             ; HL = start of unshifted image
     push de            ; DE = address for image shifted C pixels
      push de           ; two PUSH because we will POP one just before useShiftedImage
       exx
      pop hl            ; HL' = address for the shiftedimage-to-be
      exx
loopMSI:
        ld a,(hl)       ; mask1
        inc hl
        ld c,(hl)       ; graph1
        inc hl
        ld d,(hl)       ; mask2
        inc hl
        ld e,(hl)       ; graph2
        inc hl
        push hl         ; spriteImageAddr += 4
         ld hl,$FF00    ; H = 255 , L = 0
         ld b,ixl
loopMSI1:
           sll d        ; 8; ShiftLeftLogical injects a 1 in bit0 of D
           rla          ; 4
           rl h         ; 8
           sla e        ; 8; ShiftLeftArithmetic injects a 0 in bit0 of E
           rl c         ; 8
           rl l         ; 8
           djnz loopMSI1; 8+4+8+8+8+8 = 44 Ts
         ld b,a
         push de        ; D,E = mask,graph 3rd byte
          push bc       ; B,D = mask,graph 2nd byte
           push hl      ; H,L = mask,graph 1st byte
            exx
           pop de       ; D',E' = mask,graph 1st byte
           ld (hl),d
           inc hl
           ld (hl),e
           inc hl
          pop de        ; D',E' = mask,graph 2nd byte
          ld (hl),d
          inc hl
          ld (hl),e
          inc hl
         pop de         ; D',E' = mask,graph 3rd byte
         ld (hl),d
         inc hl
         ld (hl),e
         inc hl         ; HL' += 6 in this loop
         exx
        pop hl          ; spriteImageAddr
        dec ixh
        jp nz,loopMSI
     pop de             ; DE = address for image shifted C pixels
     ld ixh,16          ; 16 scanlines
     jp useShiftedImage
full:
     pop hl             ; HL = start+n*96+16+C*2 + 1
    pop bc              ; BC = backgroundAddr
    pop de              ; DE = screenAddr where drawing will start
    pop ix
    ret
    ENDP
END ASM
END SUB


#endif

