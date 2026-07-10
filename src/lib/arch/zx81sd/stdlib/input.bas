' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Simple INPUT routine (not as powerful as Sinclair BASIC's).
' Usage: A$ = INPUT(MaxChars)
'
' Version zx81sd: la version de zx48k depende de la ROM del ZX
' Spectrum (system var LAST_K actualizada por interrupcion, y la
' rutina BEEPER de la ROM). En zx81sd no hay ROM mapeada en tiempo
' de ejecucion y las interrupciones estan deshabilitadas (DI), asi
' que no existe ningun mecanismo que actualice LAST_K por si solo:
' el teclado se escanea directamente bajo demanda (ver
' runtime/io/keyboard/keyscan.asm). El pitido de tecla usa el
' beeper emulado del SD81 Booster en modo Spectrum (puerto ULA
' $FBh, ver runtime/beep.asm), no la rutina BEEPER de la ROM.
' ----------------------------------------------------------------
#ifndef __LIBRARY_INPUT__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_INPUT__

#include once <pos.bas>
#include once <csrlin.bas>

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Escanea el teclado hasta que se pulsa una tecla, y hasta que se
' suelta antes de devolver su codigo ASCII (evita que una pulsacion
' se registre varias veces mientras dura el bucle DO/LOOP).
' ------------------------------------------------------------------
FUNCTION FASTCALL PRIVATEInputWaitKey AS UBYTE
    ASM
    push namespace core
    PROC
    LOCAL WAIT_PRESS
    LOCAL WAIT_RELEASE

WAIT_PRESS:
    call __ZX81SD_KEYSCAN
    or a
    jr z, WAIT_PRESS

    ld b, a
    push bc             ; __ZX81SD_KEYCLICK usa B como contador de retardo
    call __ZX81SD_KEYCLICK
    pop bc

WAIT_RELEASE:
    push bc
    call __ZX81SD_KEYSCAN
    pop bc
    or a
    jr nz, WAIT_RELEASE

    ld a, b
    ENDP
    pop namespace
    END ASM
END FUNCTION
#require "io/keyboard/keyscan.asm"
#require "beep.asm"

' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Dado el codigo ASCII de una tecla normal (sin modificadores), da el
' simbolo del ZX81 que le corresponde bajo el antiguo SHIFT del ZX81
' (o 0 si no tiene). Ver runtime/io/keyboard/keyscan.asm: SHIFT se ha
' redefinido para dar mayuscula, asi que esos simbolos ya no se pueden
' teclear pulsando dos teclas a la vez (no da tiempo entre pulsaciones
' humanas, sobre todo leyendo desde INPUT); en su lugar, aqui se pulsan
' de manera secuencial: primero "." y luego la tecla del simbolo.
' ------------------------------------------------------------------
FUNCTION FASTCALL PRIVATEInputSymbolFor(ch AS UByte) AS UByte
    ASM
    push namespace core
    call __ZX81SD_SYMBOL_FOR
    pop namespace
    END ASM
END FUNCTION


FUNCTION input(MaxLen AS UINTEGER) AS STRING
    DIM result$ AS STRING
    DIM i as UINTEGER
    DIM LastK as UByte
    DIM sym as UByte

    result$ = ""

    DO
        PRIVATEInputShowCursor()

        REM Espera a que se pulse una tecla y a que se suelte (debounce)
        LastK = PRIVATEInputWaitKey()

        PRIVATEInputHideCursor()

        IF LastK = CODE(".") THEN
            REM Posible simbolo compuesto: "." seguido de otra tecla,
            REM pulsadas una detras de otra (no a la vez). Se lee la
            REM siguiente tecla y se comprueba si tiene simbolo.
            PRIVATEInputShowCursor()
            LastK = PRIVATEInputWaitKey()
            PRIVATEInputHideCursor()

            IF LastK = CODE(".") THEN
                REM Punto dos veces seguidas: confirma el primer punto
                REM como literal y descarta el combo (la coma ya sale
                REM directamente con SHIFT+"."). La segunda pulsacion
                REM se consume sin mas: no abre un nuevo combo ni se
                REM imprime por si misma, asi la tecla que venga a
                REM continuacion se lee como una pulsacion nueva, sin
                REM combinar - permite escribir un punto delante de una
                REM letra que de otro modo formaria simbolo con ella.
                IF LEN(result$) < MaxLen THEN
                    LET result$ = result$ + "."
                    PRINT ".";
                END IF
                LET LastK = 0
            ELSE
                REM sym=12 (RUBOUT, tecla "0") se excluye a proposito: ya
                REM se alcanza comodamente con SHIFT+0, y aceptarlo aqui
                REM haria que escribir un numero decimal terminado en
                REM ".0" (muy habitual) borrase el caracter anterior en
                REM vez de escribir el "0".
                sym = PRIVATEInputSymbolFor(LastK)
                IF sym <> 0 AND sym <> 12 THEN
                    LET LastK = sym
                ELSEIF LEN(result$) < MaxLen THEN
                    LET result$ = result$ + "."
                    PRINT ".";
                END IF
                REM Si no habia simbolo valido, LastK sigue siendo la
                REM segunda tecla real y se procesa a continuacion con
                REM normalidad: DEL, ENTER, o un caracter mas.
            END IF
        END IF

        IF LastK = 12 THEN
            IF LEN(result$) THEN REM "Del" key code is 12
                IF LEN(result$) = 1 THEN
                    LET result$ = ""
                ELSE
                    LET result$ = result$( TO LEN(result$) - 2)
                END IF
                PRINT CHR$(8);
            END IF
        ELSEIF LastK >= CODE(" ") AND LEN(result$) < MaxLen THEN
            LET result$ = result$ + CHR$(LastK)
            PRINT CHR$(LastK);
        END IF

    LOOP UNTIL LastK = 13 : REM "Enter" key code is 13

    FOR i = 1 TO LEN(result$):
        PRINT OVER 0; CHR$(8) + " " + chr$(8);
    NEXT

    RETURN result$

END FUNCTION

#pragma pop(case_insensitive)

' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Shows a flashing cursor
' ------------------------------------------------------------------
SUB PRIVATEInputShowCursor
    REM Print a Flashing cursor at current print position
    DIM x, y as UBYTE
    y = csrlin()
    x = pos()
    PRINT AT y, x; OVER 0; FLASH 1; " "; AT y, x;
END SUB


' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Hides the flashing cursor
' ------------------------------------------------------------------
SUB PRIVATEInputHideCursor
    REM Print a Flashing cursor at current print position
    DIM x, y as UBYTE
    y = csrlin()
    x = pos()
    PRINT AT y, x; OVER 0; FLASH 0; " "; AT y, x;
END SUB

#endif
