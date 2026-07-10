' vim:ts=4:et:
' ---------------------------------------------------------
' 64 Characters wide PRINT Routine for ZX BASIC
' Contributed by Britlion
'
' Override zx81sd: la version zx48k asume las direcciones fijas de la
' ROM del Spectrum para pantalla/atributos ($4000/$5800, aqui "64"/"88"
' como bytes altos) y el sysvar fijo ATTR_P (23693). En zx81sd,
' SCREEN_ADDR/SCREEN_ATTR_ADDR son variables (bloque 6, $C000/$D800) y
' ATTR_P vive en $800E (namespace core, ver sysvars.asm -- de ahi el
' prefijo .core. en las referencias de mas abajo). El charset de este
' fichero (p64_charset) es propio, no depende de la ROM, asi que no
' hace falta tocarlo. Igual que en print42.bas, las dos constantes de
' base de pantalla/atributos se parchean una vez al entrar en
' print64(), leyendo el byte alto real de SCREEN_ADDR/SCREEN_ATTR_ADDR.
' ---------------------------------------------------------

#ifndef __PRINT64__
#define __PRINT64__

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' Changes print coordinates.
SUB printat64 (y as uByte, x as uByte)
    POKE @p64coords,x
    POKE @p64coords+1,y
END sub

' Print given string at current position
SUB print64 (characters$ as String)
    asm
    ; No hace '#include once <sysvars.asm>' aqui: si esta libreria fuera
    ; la primera en incluirlo en todo el programa, arrastraria tambien
    ; bootstrap.asm/charset.asm (con su INCBIN del font completo) justo
    ; en medio de este cuerpo de funcion, ejecutandose como si fueran
    ; instrucciones (bug real, encontrado al portar este fichero). Las
    ; referencias a ATTR_P/SCREEN_ADDR/SCREEN_ATTR_ADDR de mas abajo
    ; confian en que sysvars.asm ya este incluido por el resto del
    ; runtime (CLS/PRINT lo requieren siempre, y este fichero no tiene
    ; sentido usarlo sin ellos).
    PROC    ; Declares begin of procedure
            ; so we can now use LOCAL labels

    ; Parchea las constantes de base de pantalla/atributos usadas mas
    ; abajo (ver p64_SCR_HI/p64_ATTR_HI) con los bytes altos reales de
    ; .core.SCREEN_ADDR/.core.SCREEN_ATTR_ADDR de este programa.
    LOCAL p64_SCR_HI, p64_ATTR_HI
    ld a, (.core.SCREEN_ADDR+1)
    ld (p64_SCR_HI+1), a
    ld a, (.core.SCREEN_ATTR_ADDR+1)
    ld (p64_ATTR_HI+1), a

    LD L,(IX+4)
    LD H,(IX+5) ; Get String address of characters$ into HL.

    ld a, h
    or l
    jp z, p64_END       ; Return if NULL string

    ; Load BC with length of string, and move HL to point to first character.
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl

    ; Test string length. If Zero, exit.
    ld a, c
    or b
    jp z, p64_END

    LOCAL examineChar
    examineChar:
            ld a, (hl)               ; Grab the character
            cp 128                   ; too high to print?
            jr nc, nextChar          ; then we go to next.

            cp 22                    ; Is this an AT?
            jr nz, newLine           ; If not, hop to newLine routine.
            ex de, hl                ; Swap DE and HL
            and a                    ; Clear Carry
            ld hl, 2                 ;
            sbc hl, bc               ; Can we Shorten our string length by 2? If not then at (y,x) doesn't make sense.
            ex de, hl                ; Swap DE and HL back
            jp nc, p64_END           ; If we went negative, there wasn't anything to AT to, so we return.

            inc hl                   ; Onto our Y co-ordinate
            ld d, (hl)               ; And load it into D
            dec bc                   ; Shorten our remaining string counter.
            inc hl                   ; Onto the X Co-ordinate
            ld e, (hl)               ; Load it into E
            dec bc                   ; Shorten our remaining string counter
            call p64_test_X          ; Make xy legal
            jr p64_eaa3              ; Go to save coords

    LOCAL newLine
    newLine:
            cp 13                    ; Is this a newline character?
            jr nz, p64_isPrintable   ; If not, hop to testing to see if we can print this
            ld de, (p64_coords)      ; Get coords
            call p64_nxtLine         ; Go to next line.

    LOCAL p64_eaa3
    p64_eaa3:
            ld (p64_coords), de
            jr nextChar

    LOCAL p64_isPrintable
    p64_isPrintable:
            cp 31                    ; Bigger than 31?
            jr c, nextChar           ; If not, get the next one.
            push hl                  ; Save position
            push bc                  ; Save Count
            call p64_PrintChar       ; Call Print SubRoutine
            pop bc                   ; Recover length count
            pop hl                   ; Recover Position

    LOCAL nextChar
    nextChar:
            inc hl                   ; Point to next character
            dec bc                   ; Count off this character
            ld a, b                  ; Did we run out?
            or c
            jr nz, examineChar       ; If not, examine the next one
            jp p64_END               ; Otherwise hop to END.

    LOCAL p64_PrintChar
    p64_PrintChar:
            exx
            push hl                  ; Save HL'
            exx
            sub 32                   ; Take out 32 to convert ascii to position in charset
            ld h, 0
            rra                      ; Divide by 2
            ld l, a                  ; Put our halved value into HL
            ld a, 240                ; Set our mask to LEFT side
            jr nc, p64_eacc          ; If we didn't have a carry (even #), hop forward.
            ld a, 15                 ; If we were ab idd #, set our mask to RIGHT side instead

    LOCAL p64_eacc
    p64_eacc:
            add hl, hl
            add hl, hl
            add hl, hl               ; Multiply our char number by 8
            ld de, p64_charset       ; Get our Charset position
            add hl, de               ; And add our character count, so we're now pointed at the first
                                     ; byte of the right character.
            exx
            ld de, (p64_coords)
            ex af, af'
            call p64_loadAndTest
            ex af, af'
            inc e
            ld (p64_coords), de      ; Put position+1 into coords
            dec e
            ld b, a
            rr e                     ; Divide X position by 2
            ld c, 0
            rl c                     ; Bring carry flag into C (result of odd/even position)
            and 1                    ; Mask out lowest bit in A
            xor c                    ; XOR with C (Matches position RightLeft with Char RightLeft)
            ld c, a
            jr z, p64_eaf6           ; If they are both the same, skip rotation.
            ld a, b
            rrca
            rrca
            rrca
            rrca
            ld b, a

    LOCAL p64_eaf6
    p64_eaf6:
            ld a, d                  ; Get Y coord
            sra a
            sra a
            sra a                    ; Multiply by 8
    p64_ATTR_HI:
            add a, 88                ; Attribute area high byte (parcheado con .core.SCREEN_ATTR_ADDR+1 al entrar en print64)
            ld h, a                  ; Put high byte value for attribute into H.
            ld a, d
            and 7
            rrca
            rrca
            rrca
            add a, e
            ld l, a                  ; Put low byte for attribute into l
            ld a, (.core.ATTR_P)           ; Get permanent Colours from our own sysvar
            ld (hl), a               ; Write new attribute

            ld a, d
            and 248
    p64_SCR_HI:
            add a, 64                ; Screen bitmap high byte (parcheado con .core.SCREEN_ADDR+1 al entrar en print64)
            ld h, a
            ld a, b
            cpl
            ld e, a
            exx
            ld b, 8

    LOCAL p64_eb18
    p64_eb18:
            ld a, (hl)
            exx
            bit 0, c
            jr z, p64_eb22
            rrca
            rrca
            rrca
            rrca

    LOCAL p64_eb22
    p64_eb22:
            and b
            ld d, a
            ld a, (hl)
            and e
            or d
            ld (hl), a
            inc h
            exx
            inc hl
            djnz p64_eb18
            exx
            pop hl
            exx
            ret

    LOCAL p64_loadAndTest
    p64_loadAndTest:
            ld de, (p64_coords)

    ; SubRoutine to go to legal character position.
    LOCAL p64_test_X
    p64_test_X:
            ld a, e                   ; Get column from e
            cp 64                     ; more than 64 ?
            jr c, p64_test_Y          ; If not, then jump over nextline

    LOCAL p64_nxtLine
    p64_nxtLine:
            inc d                     ; Move down 1
            ld e, 0                   ; reset x co-ord to zero

    LOCAL p64_test_Y
    p64_test_Y:
            ld a, d                   ; get Y co-ord
            cp 24                     ; Past 24?
            ret c                     ; Return if not.
            ld d, 0                   ; Rest y co-ord to top of screen.
            ret                       ; Return.
    end asm
    p64coords:
    asm
    LOCAL p64_coords;
    p64_coords:
           defb 64;  X Coordinate store
           defb 23;  Y Coordinate Store

    LOCAL p64_charset
    p64_charset:
            DEFB 0,2,2,2,2,0,2,0                   ; Space !
            DEFB 0,80,82,7,2,7,2,0                 ; "" #
            DEFB 0,37,113,66,114,20,117,32         ; $ %
            DEFB 0,34,84,32,96,80,96,0             ; & '
            DEFB 0,36,66,66,66,66,36,0             ; ( )
            DEFB 0,0,82,34,119,34,82,0             ; * +
            DEFB 0,0,0,0,7,32,32,64                ; , -
            DEFB 0,1,1,2,2,100,100,0               ; . /
            DEFB 0,34,86,82,82,82,39,0             ; 0 1
            DEFB 0,34,85,18,33,69,114,0            ; 2 3
            DEFB 0,87,84,118,17,21,18,0            ; 4 5
            DEFB 0,55,65,97,82,84,36,0             ; 6 7
            DEFB 0,34,85,37,83,85,34,0             ; 8 9
            DEFB 0,0,2,32,0,34,2,4                 ; : ;
            DEFB 0,0,16,39,64,39,16,0              ; < =
            DEFB 0,2,69,33,18,32,66,0              ; > ?
            DEFB 0,98,149,183,181,133,101,0        ; @ A     Changed from   ;0,2,37,87,117,85,53,0
            DEFB 0,98,85,100,84,85,98,0            ; B C
            DEFB 0,103,84,86,84,84,103,0           ; D E
            DEFB 0,114,69,116,71,69,66,0           ; F G
            DEFB 0,87,82,114,82,82,87,0            ; H I
            DEFB 0,53,21,22,21,85,37,0             ; J K
            DEFB 0,69,71,71,69,69,117,0            ; L M
            DEFB 0,82,85,117,117,85,82,0           ; N O
            DEFB 0,98,85,85,103,71,67,0            ; P Q
            DEFB 0,98,85,82,97,85,82,0             ; R S
            DEFB 0,117,37,37,37,37,34,0            ; T U
            DEFB 0,85,85,85,87,39,37,0             ; V W
            DEFB 0,85,85,37,82,82,82,0             ; X Y
            DEFB 0,119,20,36,36,68,119,0           ; Z [
            DEFB 0,71,65,33,33,17,23,0             ; \ ]
            DEFB 0,32,112,32,32,32,47,0            ; ^ _
            DEFB 0,32,86,65,99,69,115,0            ; £ a
            DEFB 0,64,66,101,84,85,98,0            ; b c
            DEFB 0,16,18,53,86,84,35,0             ; d e
            DEFB 0,32,82,69,101,67,69,2            ; f g
            DEFB 0,66,64,102,82,82,87,0            ; h i
            DEFB 0,20,4,53,22,21,85,32             ; j k
            DEFB 0,64,69,71,71,85,37,0             ; l m
            DEFB 0,0,98,85,85,85,82,0              ; n o
            DEFB 0,0,99,85,85,99,65,65             ; p q
            DEFB 0,0,99,84,66,65,70,0              ; r s
            DEFB 0,64,117,69,69,85,34,0            ; t u
            DEFB 0,0,85,85,87,39,37,0              ; v w
            DEFB 0,0,85,85,35,81,85,2              ; x y
            DEFB 0,0,113,18,38,66,113,0            ; z {
            DEFB 0,32,36,34,35,34,36,0             ; | {
            DEFB 0,6,169,86,12,6,9,6               ; ~ (c)

LOCAL p64_END
    p64_END:
    ENDP
    end asm

    end sub

#pragma pop(case_insensitive)

#endif
