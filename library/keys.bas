' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_IO_KEYS__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_IO_KEYS__
#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' ----------------------------------------------------------------
' function GetKeys()
' 
' Returns:
'     Waits for a Key press and returns ASCII Code
' ----------------------------------------------------------------
function GetKey AS UByte
    Dim k AS UByte
    do
        k = CODE INKEY$
    loop UNTIL k

    return k
end function


' ----------------------------------------------------------------
' function MultiKeys(x as Ubyte)
' 
' Returns:
'    Given the ScanCode, returns 0 if the given key(s) are not 
'    pressed, not zero otherwise
'
' Scancodes are like SC_ENTER, SC_SPACE
' ----------------------------------------------------------------
function FASTCALL MultiKeys(scancode as UInteger) AS UByte
    asm
        ld a, h
        in a, (0FEh)
        cpl
        and l
    end asm
end function


' ----------------------------------------------------------------
' function GetKeyScanCode()
' 
' Returns:
'    The pressed Key Scan Code or 0 if none
'
' Scancodes are like SC_ENTER, SC_SPACE
' ----------------------------------------------------------------
function FASTCALL GetKeyScanCode AS UInteger
    asm
		PROC
		LOCAL END_KEY
		LOCAL LOOP
	
		ld l, 1	
		ld a, l
	LOOP:
		cpl
		ld h, a
        in a, (0FEh)
        cpl
		and 1Fh
		jr nz, END_KEY
		
		ld a, l
		rla
		ld l, a
		jr nc, LOOP
		ld h, a
	END_KEY:
		ld l, a
		ENDP
    end asm
end function

#pragma pop(case_insensitive)

REM Scan Codes

REM 1st ROW
const KEYB        AS UInteger = 07F10h
const KEYN        AS UInteger = 07F08h
const KEYM        AS UInteger = 07F04h
const KEYSYMBOL   AS UInteger = 07F02h
const KEYSPACE    AS UInteger = 07F01h

REM 2nd ROW
const KEYH        AS UInteger = 0BF10h
const KEYJ        AS UInteger = 0BF08h
const KEYK        AS UInteger = 0BF04h
const KEYL        AS UInteger = 0BF02h
const KEYENTER    AS UInteger = 0BF01h

REM 3rd ROW
const KEYY        AS UInteger = 0DF10h
const KEYU        AS UInteger = 0DF08h
const KEYI        AS UInteger = 0DF04h
const KEYO        AS UInteger = 0DF02h
const KEYP        AS UInteger = 0DF01h

REM 4th ROW
const KEY6        AS UInteger = 0EF10h
const KEY7        AS UInteger = 0EF08h
const KEY8        AS UInteger = 0EF04h
const KEY9        AS UInteger = 0EF02h
const KEY0        AS UInteger = 0EF01h

REM 5th ROW
const KEY5        AS UInteger = 0F710h
const KEY4        AS UInteger = 0F708h
const KEY3        AS UInteger = 0F704h
const KEY2        AS UInteger = 0F702h
const KEY1        AS UInteger = 0F701h

REM 6th ROW
const KEYT        AS UInteger = 0FB10h
const KEYR        AS UInteger = 0FB08h
const KEYE        AS UInteger = 0FB04h
const KEYW        AS UInteger = 0FB02h
const KEYQ        AS UInteger = 0FB01h

REM 7th ROW
const KEYG        AS UInteger = 0FD10h
const KEYF        AS UInteger = 0FD08h
const KEYD        AS UInteger = 0FD04h
const KEYS        AS UInteger = 0FD02h
const KEYA        AS UInteger = 0FD01h

REM 8th ROW
const KEYV        AS UInteger = 0FE10h
const KEYC        AS UInteger = 0FE08h
const KEYX        AS UInteger = 0FE04h
const KEYZ        AS UInteger = 0FE02h
const KEYCAPS     AS UInteger = 0FE01h

#endif

