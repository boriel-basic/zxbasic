' ----------------------------------------------------------------
' This file is released under the GPL v3 License
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

	result$ = ""
	
	DO
		PRIVATEInputShowCursor()

		REM Wait for a Key Press
		LastK = 0
		DO LOOP UNTIL LastK <> 0

		PRIVATEInputHideCursor()

		IF LastK = 12 THEN:
			IF LEN(result$) THEN : REM "Del" key code is 12
				IF LEN(result$) = 1 THEN:
					LET result$ = ""
				ELSE
					LET result$ = result$( TO LEN(result$) - 2)	
				END IF
				PRINT CHR$(8);
			END IF

		ELSE IF LastK >= CODE(" ") AND LEN(result$) < MaxLen THEN
			LET result$ = result$ + CHR$(LastK)
			PRINT CHR$(LastK);
			END IF

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
SUB FASTCALL PRIVATEInputShowCursor
	REM Print a Flashing cursor at current print position
	PRINT AT csrlin(), pos(); OVER 0; FLASH 1; " " + CHR$(8);
END SUB


' ------------------------------------------------------------------
' Function 'PRIVATE' to this module.
' Hides the flashing cursor
' ------------------------------------------------------------------
SUB FASTCALL PRIVATEInputHideCursor
	REM Print a Flashing cursor at current print position
	PRINT AT csrlin(), pos(); OVER 0; FLASH 0; " " + CHR$(8);
END SUB

#endif

