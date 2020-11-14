' ----------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Simple INPUT routine (not as powerful as Sinclair BASIC's), but
' this one uses PRINT42 routine
' Usage: A$ = INPUT42(MaxChars)
' ----------------------------------------------------------------
#ifndef __LIBRARY_INPUT42__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_INPUT42__

REM The input subroutine
REM DOES NOT act like ZX Spectrum INPUT command
REM Uses ZX SPECTRUM ROM

#include once <pos.bas>
#include once <csrlin.bas>
#include once <print42.bas>

#pragma push(case_insensitive)
#pragma case_insensitive = True

FUNCTION input42(MaxLen AS UINTEGER) AS STRING
	DIM LastK AS UBYTE AT 23560: REM LAST_K System VAR
	DIM result$ AS STRING
	DIM i as UINTEGER

	result$ = ""
    POKE 23611, PEEK 23611 bOR 8
	
	DO
		PRIVATEInputShowCursor42()

		REM Wait for a Key Press
		LastK = 0
		DO LOOP UNTIL LastK <> 0

		PRIVATEInputHideCursor42()

		IF LastK = 12 THEN
			IF LEN(result$) THEN REM "Del" key code is 12
				IF LEN(result$) = 1 THEN
					LET result$ = ""
				ELSE
					LET result$ = result$( TO LEN(result$) - 2)	
				END IF
				PRINT42 CHR$(8)
			END IF
		ELSEIF LastK >= CODE(" ") AND LEN(result$) < MaxLen THEN
			LET result$ = result$ + CHR$(LastK)
			PRINT42 CHR$(LastK)
		END IF

	LOOP UNTIL LastK = 13 : REM "Enter" key code is 13

	FOR i = 1 TO LEN(result$):
		PRINT42 CHR$(8) + " " + CHR$(8)
	NEXT
	
	RETURN result$

END FUNCTION

#pragma pop(case_insensitive)

' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Shows a flashing cursor
' ------------------------------------------------------------------
SUB FASTCALL PRIVATEInputShowCursor42
	REM Print a Flashing cursor at current print position
	OVER 1: PRINT42 "_" + CHR$(8): OVER 0
END SUB


' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Hides the flashing cursor
' ------------------------------------------------------------------
SUB FASTCALL PRIVATEInputHideCursor42
	REM Print a Flashing cursor at current print position
	OVER 0: PRINT42 " " + CHR$(8)
END SUB

#endif

