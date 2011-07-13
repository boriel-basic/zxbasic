' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_CSRLIN__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_CSRLIN__

#pragma push(case_insensitive)
#pragma case_insensitive = true

' ----------------------------------------------------------------
' function csrlin()
' 
' Returns:
'	A byte containing the current ROW printing position
' ----------------------------------------------------------------
function FASTCALL csrlin as ubyte
    asm
    PROC    ; Start new scope

    call __LOAD_S_POSN
    ld a, d

    ENDP    ; End scope
    end asm
end function

#pragma pop(case_insensitive)
#require "sposn.asm"


#endif

