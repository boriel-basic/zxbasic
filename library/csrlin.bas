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

    LOCAL S_POSN
    LOCAL ECHO_E
ECHO_E EQU 23682
S_POSN EQU 23688

    ld de, (S_POSN)
    ld hl, (ECHO_E)
    or a
    sbc hl, de
    ld a, h
    adc a, 0
    ld h, a
    ld a, e
    or a
    ld a, h
    ret nz
    inc a
    
    ENDP    ; End scope
    end asm
end function

#pragma pop(case_insensitive)


#endif

