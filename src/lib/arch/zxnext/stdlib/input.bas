' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Simple INPUT routine (not as powerful as Sinclair BASIC's).
' Usage: A$ = INPUT(MaxChars)
' ----------------------------------------------------------------
#ifndef __LIBRARY_INPUT__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_INPUT__

REM The input subroutine
REM DOES NOT act like ZX Spectrum INPUT command
REM Uses ZX SPECTRUM ROM

#include once <pos.bas>
#include once <csrlin.bas>

#pragma push(case_insensitive)
#pragma case_insensitive = True

FUNCTION input(MaxLen AS UINTEGER) AS STRING
    DIM LastK AS UBYTE AT 23560: REM LAST_K System VAR
    DIM result$ AS STRING
    DIM i as UINTEGER
    DIM tmp as UByte

    LET tmp = PEEK 23611
    POKE 23611, PEEK 23611 bOR 8 : REM sets FLAGS var to L mode

    result$ = ""

    DO
        PRIVATEInputShowCursor()

        REM Wait for a Key Press
        LastK = 0
        DO LOOP UNTIL LastK <> 0
        ASM
            PROC
            LOCAL PIP
            LOCAL NO_CLICK
            LOCAL BEEPER

            PIP EQU 23609
            BEEPER EQU 0x3B5

            ld a, (PIP)
            cp 0xFF
            jr z, NO_CLICK
            push ix
            ld e, a
            ld d, 0
            ld hl, 0x00C8
            CALL BEEPER
            pop ix

        NO_CLICK:
            ENDP

        END ASM

        PRIVATEInputHideCursor()

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

    POKE 23611, tmp : REM resets FLAGS var

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

