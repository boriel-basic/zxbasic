' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_POS__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_POS__

#pragma push(case_insensitive)
#pragma case_insensitive = true

REM Put your code here.

' ----------------------------------------------------------------
' function pos()
'
' Returns:
' 	Current COLUMN print position
' ----------------------------------------------------------------
function FASTCALL pos as ubyte
    asm
    PROC

    call __LOAD_S_POSN
    ld a, e

    ENDP
    end asm
end function

#pragma pop(case_insensitive)
#require "sposn.asm"


#endif

