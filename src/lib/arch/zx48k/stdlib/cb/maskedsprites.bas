' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyright (C) 2026 Conrado Badenas <conbamen@gmail.com>
' Ideas taken from
'   https://github.com/boriel-basic/zxbasic/blob/main/src/lib/arch/zx48k/stdlib/memorybank.bas
'       by Juan Segura (a.k.a. Duefectu),
'   https://github.com/oisee/antique-toy/blob/main/chapters/ch16-sprites/draft.md
'       by Alice Vinogradova (a.k.a. oisee), and
'   https://youtu.be/nBHXtI1Y-xU?t=434
'       by Benjamín (a.k.a. RetrobenSoft)
'
' Print Masked (AND+OR) Sprites, version 2026.03.06
' ----------------------------------------------------------------

#ifndef __CB_MASKEDSPRITES__

REM Avoid recursive / multiple inclusion

#define __CB_MASKEDSPRITES__

#include <memorybank.bas>
#include <memcopy.bas>
#include <scrbuffer.bas>


' ----------------------------------------------------------------
' Set the visible screen (either in bank5 or bank7)
' and updates the system variable BANKM.
' Only works on 128K and compatible models.
' Parameters:
'     Ubyte: bank number 5 or 7
' ----------------------------------------------------------------
SUB FASTCALL SetVisibleScreen(bankNumber AS UByte)
ASM
    ; A = bankNumber 5 or 7 with screen to be visible
    and %00000010       ; bit1 = 0/1 for bank5/7
    rla
    rla                 ; bit3 = 0/1 for bank5/7
    ld c,a
    ld hl,$5b5c         ; BANKM system variable
    ld a,(hl)           ; Read BANKM
    and %11110111       ; Reset bit3
    or c                ; Set screen in bank5/7
    ld bc,$7ffd         ; Memory Bank control port
    di                  ; Disable interrupts
    ld (hl),a           ; Update BANKM system variable
    out (c),a           ; Set the screen
    ei                  ; Enable interrupts
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
    RETURN ((PEEK $5b5c bAND %1000)>>2) bOR 5
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
SUB CopyScreen5ToScreen7()
    DIM b AS UByte

    b = GetBank()
    if b<>7 then SetBank(7)
    MemCopy($4000,$c000,$1b00)
    if b<>7 then SetBank(b)
END SUB


' ----------------------------------------------------------------
' Copy contents of screen7 to screen5 (display file + attribs)
' Only works on 128K and compatible models.
' ----------------------------------------------------------------
SUB CopyScreen7ToScreen5()
    DIM b AS UByte

    b = GetBank()
    if b<>7 then SetBank(7)
    MemCopy($c000,$4000,$1b00)
    if b<>7 then SetBank(b)
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

    b = GetBank()
    if b<>7 then SetBank(7)
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
' MaskedSpritesBackground(i) is the Dir where Background i begins
'
' ChangeMaskedSpritesBackgroundSet() changes the Set of Backgrounds
' Returns:
'     Byte: new value of MaskedSpritesBackgroundSet (IYW to use it)
' ----------------------------------------------------------------
dim MaskedSpritesBackgroundSet as Byte = 0
#define MaskedSpritesBackground(i) (56064+((i)*2+MaskedSpritesBackgroundSet)*48)
FUNCTION FASTCALL ChangeMaskedSpritesBackgroundSet() as Byte
    MaskedSpritesBackgroundSet = MaskedSpritesBackgroundSet bXOR 1
    RETURN MaskedSpritesBackgroundSet
END FUNCTION


' ----------------------------------------------------------------
' Save background and Draw sprite in screen
' Parameters:
'     UByte:    X coordinate (0:left to 240:right)
'     UByte:    Y coordinate (0:up   to 176:down)
'     UInteger: Dir where background will be saved
'     UInteger: Dir where sprite image begins
' ----------------------------------------------------------------
SUB FASTCALL SaveBackgroundAndDrawSprite(X as UByte, Y as UByte, backgroundDir as UInteger, spriteImageDir as UInteger)
ASM
    PROC
    LOCAL shiftsprite, spriteOK, loop0, loopA, loopB
    LOCAL branchA, branchB, nextA, nextB
    ; A = X
    pop de              ; returnDir
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
    ex de,hl            ; DE = screenDir where drawing will start
    ld a,c;             ; A = X
    and 7
    jr z,spriteOK       ; jump if X is a multiple of 8 (unlikely)
                        ; continue if sprite must be shifted
shiftsprite:
    pop bc              ; backgroundDir
    exx
    pop hl              ; spriteImageDir
    push de             ; returnDir
    push ix
    ld ixh,16           ; 16 scanlines
    ld ixl,a            ; IXl = X MOD 8 = 1,2,...,7
loopB:
        ld a,(hl)       ; mask1
        inc hl
        ld c,(hl)       ; graph1
        inc hl
        ld d,(hl)       ; mask2
        inc hl
        ld e,(hl)       ; graph1
        inc hl
        push hl         ; spriteImageDir

        ld hl,$FF00     ; H = 255 , L = 0
        ld b,ixl
loop0:
            scf
            rra         ; SCF + RRA injects a 1 in bit7 of A
            rr d
            rr h
            srl c       ; ShiftRightLogical injects a 0 in bit7 of C
            rr e
            rr l
            djnz loop0
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
        jr z,branchB    ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        exx
        pop hl          ; spriteImageDir
        dec ixh
        jp nz,loopB
    pop ix
    ret
branchB:        
        ld a,e
        add a,32        ; for 1 out of 8 values of D
        ld e,a
        jr c,nextB      ; 7Ts no jump (7/8 times), 12 Ts jump (1/8 times)
        ld a,d
        sub 8
        ld d,a
nextB:
        exx
        pop hl          ; spriteImageDir
        dec ixh
        jp nz,loopB
    pop ix
    ret

spriteOK:
    pop bc              ; backgroundDir
    pop hl              ; spriteImageDir
    exx
    push de             ; returnDir
    exx
    push ix
    ld ixh,16           ; 16 scanlines
loopA:
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
        jr z,branchA    ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        dec ixh
        jp nz,loopA
    pop ix
    ret
branchA:        
        ld a,e
        add a,32        ; for 1 out of 8 values of D
        ld e,a
        jr c,nextA      ; 7Ts no jump (7/8 times), 12 Ts jump (1/8 times)
        ld a,d
        sub 8
        ld d,a
nextA:
        dec ixh
        jp nz,loopA
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
'     UInteger: Dir where saved background begins
' ----------------------------------------------------------------
SUB FASTCALL RestoreBackground(X as UByte, Y as UByte, backgroundDir as UInteger)
ASM
    PROC
    LOCAL loopC, loopD, branchC, branchD, nextC, nextD
    ; A = X
    pop de              ; returnDir
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
    ex de,hl            ; DE = screenDir where restoring will start
    pop hl              ; backgroundDir
    exx
    push de             ; returnDir
    exx
    ld a,c;             ; A = X
    ld bc,$10FF         ; B = 16, C = 255 (up to 255 LDIs do not change B)
    and 7
    jr z,loopD          ; jump if X is a multiple of 8 (unlikely)
                        ; continue if restoring 3 bytes per scanline
loopC:
        ldi             ; 16 Ts vs 7+7+6+4=24 Ts
        ldi
        ldi             ; 3 bytes background restored to screen
        dec de          ; last LDI could have increased D if initially E=253...
        dec e           ; ...so DEC DE restores D in that case
        dec e

        inc d
        ld a,d
        and 7
        jr z,branchC    ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        djnz loopC
    ret
branchC:        
        ld a,e
        add a,32        ; for 1 out of 8 values of D
        ld e,a
        jr c,nextC      ; 7Ts no jump (7/8 times), 12 Ts jump (1/8 times)
        ld a,d
        sub 8
        ld d,a
nextC:
        djnz loopC
    ret

loopD:
        ldi             ; 16 Ts vs 7+7+6+4=24 Ts
        ldi             ; 2 bytes background restored to screen
        dec de          ; last LDI could have increased D if initially E=254...
        dec e           ; ...so DEC DE restores D in that case

        inc d
        ld a,d
        and 7
        jr z,branchD    ; 7Ts no jump (7/8 times), 12Ts jump (1/8 times)
        djnz loopD
    ret
branchD:        
        ld a,e
        add a,32        ; for 1 out of 8 values of D
        ld e,a
        jr c,nextD      ; 7Ts no jump (7/8 times), 12 Ts jump (1/8 times)
        ld a,d
        sub 8
        ld d,a
nextD:
        djnz loopD
    ret
    ENDP
END ASM
END SUB


#endif

