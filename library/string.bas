' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_STRING__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_STRING__

#pragma push(case_insensitive)
#pragma case_insensitive = true

#pragma push(string_base)
#pragma string_base = 0

#define __MAX_LEN__ 65535


' ----------------------------------------------------------------
' function mid$(A$, <from>, <len>)
'
' Returns:
' 	Substring starting at <from>, with <len> chars.
' ----------------------------------------------------------------
function mid$(ByVal s$, ByVal x As Uinteger, ByVal n As Uinteger)
    return s$(x to x + n - 1)
end function


' ----------------------------------------------------------------
' function Left$(A$, <len>)
'
' Returns:
'   The first <len> chars of the given string.
' ----------------------------------------------------------------
function left$(ByVal s$, ByVal n As Uinteger)
    return s$(TO n - 1)
end function


' ----------------------------------------------------------------
' function Right$(A$, <len>)
'
' Returns:
'   The last <len> chars of the given string.
' ----------------------------------------------------------------
function right$(ByVal s$, ByVal n As Uinteger)
    return s$(len(s$) - n TO)
end function


' ----------------------------------------------------------------
' function strpos(A$, b$)
'
' Returns:
'   The position of b$ in A$
'   If b$ is not in A$, it will return a value greater than
'   LEN(a$)
' ----------------------------------------------------------------
function strpos(ByVal a$, ByVal b$) as Uinteger
    dim la, lb, lb1, i as Uinteger
    la = len(a$)
    lb = len(b$)
    lb1 = lb - 1

    for i = 0 to la - lb
        if b$ = a$(i TO i + lb1) then
            return i
        end if
    next

    return __MAX_LEN__ : REM 'Not found
end function




#undef __MAX_LEN__

#pragma pop(string_base)
#pragma pop(case_insensitive)


#endif      ' __LIBRARY_STRING__

