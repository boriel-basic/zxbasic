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
'
' Version zx81sd (2026-07-04): la version de zx48k asume paginacion de
' memoria al estilo Spectrum 128K (banco visible en $c000-$ffff via
' puerto $7FFDh, sysvar BANKM en $5B5C) para el subsistema MSFS (Masked
' Sprites File System, un almacen de imagenes de sprite en RAM de
' sobra). Nada de eso existe en zx81sd. Se sustituye por el mapeador de
' memoria propio (puerto $E7h) sobre el BLOQUE 7 ($E000-$FFFF), que en
' nuestro mapa de memoria ya esta reservado para "banking de datos
' (mapas, sprites...)" -- justo este caso de uso.
'
' Las funciones de MSFS (RegisterSpriteImageInMSFS, FindFirstUnusedBlock
' InMSFS, etc.) son agnosticas de banco/direccion: solo llaman a
' GetBankPreservingRegs/SetBankPreservingINTs y leen/escriben la
' variable BASIC MaskedSpritesFileSystemStart. Reescribiendo esas DOS
' primitivas (y el calculo de esa direccion en InitMaskedSpritesFileSystem,
' mas abajo, que en el original asumia RAM plana Spectrum hasta $FFFF)
' el resto del fichero se copia sin tocar una sola linea.
'
' CheckMemoryPaging() aqui solo influye, en el ejemplo, en si se usa
' pantalla visible doble (bancos 5/7 del Spectrum) -- zx81sd tiene un
' unico framebuffer fisico (bloque 6, SCREEN_ADDR fijo en $C000) y esa
' funcionalidad no esta cubierta aqui (ver nota en SetVisibleScreen mas
' abajo). Las funciones de MSFS NO consultan CheckMemoryPaging() para
' decidir si usar el banco -- lo hacen incondicionalmente -- asi que
' devolver 0 (honesto: no hay doble pantalla visible) no le afecta en
' nada a que MSFS funcione.
'
' RESIDENCIA: desde InitMaskedSpritesFileSystem(), la pagina de MSFS se
' queda mapeada de forma PERMANENTE en el bloque 7 (SetBankPreservingINTs
' con valor <> 7 solo anota el numero, no desmapea) -- las rutinas de
' dibujo del bucle principal acceden a la MSFS sin envolver con
' Get/SetBank y necesitan verla siempre. Si un programa usa el bloque 7
' para su propio banking de datos, debe remapear su pagina el mismo y
' llamar a SetBankPreservingINTs(7) antes de volver a usar MSFS.
' ----------------------------------------------------------------

#ifndef __CB_MASKEDSPRITES__

REM Avoid recursive / multiple inclusion

#define __CB_MASKEDSPRITES__

#include <memcopy.bas>
#include <scrbuffer.bas>
#include <mcu.bas>


' ----------------------------------------------------------------
' Banco de MSFS sobre el mapeador de zx81sd (puerto $E7h, bloque 7)
'
' MaskedSprites_MSFS_Page es la pagina SD81 dedicada a guardar la MSFS.
' Debe evitar las paginas 8-13 (codigo/heap, fijas por el bootstrap, ver
' src/arch/zx81sd/backend/main.py _PAGE_MAP) y 63 (pagina "libre" por
' convencion del cargador SD81: split_sd81.py deja siempre el bloque 7
' apuntando a la pagina 63 tras cargar, antes de saltar al programa).
' Redefinible con #define ANTES de este #include si el programa ya usa
' la pagina 20 para otra cosa (no hay todavia un asignador global de
' paginas en el proyecto).
' ----------------------------------------------------------------
#ifndef MaskedSprites_MSFS_Page
    #define MaskedSprites_MSFS_Page 20
#endif

' Byte de estado puro en ASM (no DIM): un DIM normal se eliminaria por
' "codigo muerto" al no tener ninguna referencia desde BASIC (solo se
' toca desde las dos rutinas ASM de abajo).
ASM
_ZX81SD_MSFS_Bank:
    DEFB 0
END ASM

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
'
' Version zx81sd: "banco" aqui es puramente logico. Con 7 se asegura que
' la pagina de MSFS este mapeada en el bloque 7; con cualquier otro
' valor SOLO se anota el numero (la pagina de MSFS se queda RESIDENTE,
' no se desmapea). Motivo: SaveBackgroundAndDrawSpriteRegisteredInMSFS
' (el que dibuja en el bucle principal, y el que crea imagenes
' desplazadas bajo demanda) accede a la MSFS SIN envolver con
' Get/SetBank -- en el diseno original no lo necesita porque en 128K el
' banco 7 se queda mapeado en $c000 (SetDrawingScreen7) y en 48K la
' MSFS esta en RAM plana siempre visible. Una primera version de este
' override "liberaba" el bloque 7 a la pagina 63 al restaurar tras
' Init/Register... y el dibujo del bucle principal leia mascaras y
' graficos de la pagina 63 (basura): sprites como lineas verticales.
' Si un programa usa el bloque 7 para su propio banking de datos,
' debe remapear su pagina el mismo y volver a llamar aqui con 7 antes
' de usar MSFS (documentado tambien en la cabecera del fichero).
'
' No hace falta preservar interrupciones: en zx81sd estan
' permanentemente deshabilitadas (DI todo el tiempo). IMPORTANTE:
' escrita en ASM a mano (no en BASIC plano) para respetar EXACTAMENTE
' el contrato de registros de arriba -- RegisterSpriteImageInMSFS y
' companeros confian en que D,E,H,L sobrevivan a esta llamada (por
' ejemplo, para no perder spriteImageAddr, que llega en HL); una
' implementacion en BASIC normal no da esa garantia (usa registros
' libremente por dentro) y provocaba que todos los sprites se
' registraran en la misma direccion.
' ----------------------------------------------------------------
SUB FASTCALL SetBankPreservingINTs(bankNumber AS UByte)
ASM
    PROC
    LOCAL NO_MAP
    ld (_ZX81SD_MSFS_Bank), a
    cp 7
    jr nz, NO_MAP                   ; banco logico <> 7: solo anotar, la
                                    ; pagina de MSFS se queda residente
    push de
    push hl
    ld d, MaskedSprites_MSFS_Page
    ld e, 0
    push de                         ; parametro 'page' de Map (byte alto = D)
    ld a, 7                         ; parametro 'block' de Map (bloque 7, fijo)
    call _Map
    pop hl
    pop de
NO_MAP:
    ENDP
END ASM
END SUB


' ----------------------------------------------------------------
' Get which RAM bank is set in addresses $c000-$ffff
' Only works on 128K and compatible models.
' Preserves:
'     B, C, D, E, H, L are not used
' Returns:
'     UByte: bank number 0,1,2,3,4,5,6,7
'
' Version zx81sd: devuelve el "banco logico" guardado por la ultima
' llamada a SetBankPreservingINTs (ver arriba). En ASM a mano por el
' mismo motivo que SetBankPreservingINTs: preservar B,C,D,E,H,L de
' verdad para las rutinas de MSFS que dependen de ello.
' ----------------------------------------------------------------
FUNCTION FASTCALL GetBankPreservingRegs() AS UByte
ASM
    ld a, (_ZX81SD_MSFS_Bank)
END ASM
END FUNCTION


' ----------------------------------------------------------------
' Check whether memory paging works (128,+2,...) or not (16,48)
' Returns:
'     UByte: 1 if paging works, 0 if it does not
'
' Version zx81sd: siempre devuelve 0. No existe paginacion de pantalla
' visible al estilo Spectrum 128K (un unico framebuffer fisico, bloque
' 6); ver la nota de cabecera de este fichero sobre por que esto no
' afecta a que MSFS funcione (usa el mapeador propio, no esta funcion).
' ----------------------------------------------------------------
FUNCTION FASTCALL CheckMemoryPaging() AS UByte
    RETURN 0
END FUNCTION


' ----------------------------------------------------------------
' Set the visible screen (either in bank5 or bank7)
' and updates the system variable BANKM.
' Only works on 128K and compatible models.
' Parameters:
'     Ubyte: bank number 5 or 7
' Preserves:
'     D, E, H, L are not used
'
' Version zx81sd: no existe hardware de doble pantalla visible
' intercambiable (bancos 5/7 del Spectrum 128K) -- zx81sd solo tiene un
' framebuffer fisico (bloque 6, SCREEN_ADDR fijo en $C000). Se deja como
' stub seguro (no toca $5B5C ni el puerto $7FFD, que no existen aqui);
' CheckMemoryPaging() devuelve 0, asi que en la practica nunca se llama
' de verdad. Doble buffer de pantalla real (alternando que pagina
' respalda el bloque 6 via el mapeador) seria una funcionalidad aparte,
' no cubierta aqui.
' ----------------------------------------------------------------
SUB FASTCALL SetVisibleScreen(bankNumber AS UByte)
END SUB


' ----------------------------------------------------------------
' Returns the bank of visible screen (either 5 or 7)
' according to system variable BANKM.
' Only works on 128K and compatible models.
' Returns:
'     UByte: bank 5 or 7
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba.
' ----------------------------------------------------------------
FUNCTION FASTCALL GetVisibleScreen() AS UByte
    RETURN 5
END FUNCTION


' ----------------------------------------------------------------
' Toggles the visible screen (from 5 to 7, or from 7 to 5)
' and updates the system variable BANKM.
' Only works on 128K and compatible models.
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba.
' ----------------------------------------------------------------
SUB FASTCALL ToggleVisibleScreen()
END SUB


' ----------------------------------------------------------------
' Copy contents of screen5 to screen7 (display file + attribs)
' Only works on 128K and compatible models.
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba.
' ----------------------------------------------------------------
SUB FASTCALL CopyScreen5ToScreen7()
END SUB


' ----------------------------------------------------------------
' Copy contents of screen7 to screen5 (display file + attribs)
' Only works on 128K and compatible models.
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba.
' ----------------------------------------------------------------
SUB FASTCALL CopyScreen7ToScreen5()
END SUB


' ----------------------------------------------------------------
' Set ScreenBufferAddr and AttrBufferAddr to screen5
' Only works on 128K and compatible models.
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba. IMPORTANTE:
' NO se puede simplemente copiar el original -- SetScreenBufferAddr($4000)
' redirigiria SCREEN_ADDR a plena zona de codigo/runtime ($1000-$7FFF en
' nuestro mapa de memoria), corrompiendo cualquier PRINT/grafico
' posterior. Se deja vacia.
' ----------------------------------------------------------------
SUB FASTCALL SetDrawingScreen5()
END SUB


' ----------------------------------------------------------------
' Put screen7 at $c000 (in case it is not), and
' Set ScreenBufferAddr and AttrBufferAddr to screen7
' Only works on 128K and compatible models.
' Returns:
'     Bank7 is set at $c000, old bank is removed
'     UByte: bank that was at $c000 (to restore it manually IYW)
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba. $c000/$d800
' coinciden por casualidad con nuestro SCREEN_ADDR/SCREEN_ATTR_ADDR
' reales, pero esta funcion tambien mapea banco7 (aqui reinterpretado
' como el banco de MSFS) al bloque 7, no al bloque 6 (pantalla) -- no
' hay overlap real posible entre "pantalla" y "banco 7" en zx81sd, asi
' que se deja como no-op en vez de fingir un intercambio que no existe.
' ----------------------------------------------------------------
FUNCTION FASTCALL SetDrawingScreen7() AS UByte
    RETURN 5
END FUNCTION


' ----------------------------------------------------------------
' Toggle ScreenBufferAddr and AttrBufferAddr between screen5,7
' Only works on 128K and compatible models.
'
' Version zx81sd: stub seguro, ver SetVisibleScreen arriba.
' ----------------------------------------------------------------
SUB FASTCALL ToggleDrawingScreen()
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
'
' Version zx81sd: MaskedSpritesFileSystemStart es una direccion FIJA
' dentro del bloque 7 ($E000, la pagina dedicada MaskedSprites_MSFS_Page)
' en vez de "lo que quede hasta $FFFF" (el original asumia RAM plana
' Spectrum ahi, que en zx81sd es una ventana paginada de 8K, no RAM
' contigua). Con $E000: l = Int((65536-57344)/96) = 85 bloques -- toda
' la MSFS cabe de sobra en los 8K del bloque 7. El resto de la funcion
' (calculo de bytes del FSB, pokes) es identico al original. Se llama
' siempre a SetBankPreservingINTs(7) (no gated por CheckMemoryPaging(),
' que aqui es irrelevante para MSFS -- ver cabecera del fichero).
' ----------------------------------------------------------------
FUNCTION FASTCALL InitMaskedSpritesFileSystem() AS UInteger
    DIM b AS UByte
    DIM l, j AS UInteger

    b = GetBankPreservingRegs()
    if b<>7 then SetBankPreservingINTs(7)
    ' Llamada BASIC explicita a Map(), redundante con la que ya hace
    ' SetBankPreservingINTs por ASM a mano (mapea el mismo bloque/pagina
    ' otra vez, sin efecto): el analisis de "codigo muerto" del
    ' compilador no cuenta las llamadas hechas desde ASM como uso, y sin
    ' esto Map() se elimina del binario -> "Undefined GLOBAL label" al
    ' intentar llamarla desde dentro de SetBankPreservingINTs.
    Map(7, MaskedSprites_MSFS_Page)
    MaskedSpritesFileSystemStart = $E000
    l = -MaskedSpritesFileSystemStart
    l = Int(l/96)
    poke MaskedSpritesFileSystemStart,  l ' MSFS blocks = FSB bits
    if l=0 then STOP
    l = 1+Int((l-1)/8)
    poke MaskedSpritesFileSystemStart+1,l ' FSB bytes
    ' Limpiar el FSB (bitmap de bloques libres, bytes start+2..start+1+l).
    ' Ni esta version ni la original de zx48k lo inicializaban: en el
    ' Spectrum no hace falta porque el test de RAM de la ROM deja toda
    ' la memoria a cero en el arranque, asi que el bitmap nace "todo
    ' libre" gratis. En zx81sd la pagina del bloque 7 llega con basura
    ' de fabrica: todos los bits aparecian a 1 ("ocupado"),
    ' FindFirstUnusedBlockInMSFS recorria el FSB entero sin encontrar
    ' hueco y RegisterSpriteImageInMSFS devolvia siempre 0 (lleno).
    FOR j = MaskedSpritesFileSystemStart+2 TO MaskedSpritesFileSystemStart+1+l
        poke j, 0
    NEXT j
    if b<>7 then SetBankPreservingINTs(b)
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

