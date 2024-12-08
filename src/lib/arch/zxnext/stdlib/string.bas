' ----------------------------------------------------------------
' This file is released under the MIT License
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
function mid$(ByVal s$ as String, ByVal x As Uinteger, ByVal n As Uinteger) as String
    return s$(x to x + n - 1)
end function


' ----------------------------------------------------------------
' function Left$(A$, <len>)
'
' Returns:
'   The first <len> chars of the given string.
' ----------------------------------------------------------------
function left$(ByVal s$ as String, ByVal n As Uinteger) As String
    return s$(TO n - 1)
end function


' ----------------------------------------------------------------
' function Right$(A$, <len>)
'
' Returns:
'   The last <len> chars of the given string.
' ----------------------------------------------------------------
function right$(ByVal s$ as String, ByVal n As Uinteger) As String
    return s$(len(s$) - n TO)
end function


' ----------------------------------------------------------------
' function strpos2(A$, b$)
'
' Unlike strpos, parameters must be Variables, not expressions.
' This way it requires less memory (heap) and it's faster
'
' Returns:
'   The position of b$ in A$
'   If b$ is not in A$, it will return a value greater than
'   LEN(a$)
' ----------------------------------------------------------------
function strpos2(ByRef a$ as String, ByRef b$ As String) as Uinteger
    dim la, lb, l, lb1, i as Uinteger
    la = len(a$)
    lb = len(b$)

    if lb > la then ' len(b$) must be <= len (a$)
        return __MAX_LEN__ 'Not found
    end if

    l = la - lb
    lb1 = lb - 1

    for i = 0 to l
        if b$ = a$(i TO i + lb1) then
            return i
        end if
    next

    return __MAX_LEN__ 'Not found
end function



' ----------------------------------------------------------------
' function strpos(A$, b$)
'
' Returns:
'   The position of b$ in A$
'   If b$ is not in A$, it will return a value greater than
'   LEN(a$)
' ----------------------------------------------------------------
function strpos(ByVal a$ as String, ByVal b$ as String) as Uinteger
    return strpos2(a$, b$)
end function



' ----------------------------------------------------------------
' function instr(A$, b$)
'
' Returns:
'   0 if b$ not in a$
'   other value if b$ is in a$
' ----------------------------------------------------------------
function inStr(ByVal a$ as String, ByVal b$ as String) as byte
    DIM i as Uinteger
    i = strpos2(a$, b$)
    return i <> __MAX_LEN__
end function



' ----------------------------------------------------------------
' Sub Ucase2(ByRef b$)
'
' - Converts the content of b$ to uppercase
' ----------------------------------------------------------------
sub FASTCALL ucase2$(ByRef s$ as String) 
    asm

    PROC

    LOCAL __LOOP

    ; ld hl, (hl)
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    
    ; ret if NULL
    ld a, h
    or l
    ret z

    ld c, (hl)
    inc hl
    ld b, (hl)

__LOOP:
    inc hl
    ld a, b
    or c
    ret z

    ld a, (hl)
    dec bc

    cp 'a'
    jp c, __LOOP ; If a < 'a' NEXT
    cp 123   ; 'z' + 1
    jp nc, __LOOP ; If a > 'z' NEXT

    res 5,(hl)
    jp __LOOP
    
    ENDP

    end asm
end sub


' ----------------------------------------------------------------
' function Ucase(ByVal b$)
'
' - Returns a copy of b$ converted to uppercase
' ----------------------------------------------------------------
function ucase(ByVal s$ as String) as String
    ucase2(s$)
    return s$
end function


' ----------------------------------------------------------------
' Sub Lcase2(ByRef b$)
'
' - Converts the content of b$ to lowercase
' ----------------------------------------------------------------
sub FASTCALL lcase2$(ByRef s$ as String) 
    asm

    PROC

    LOCAL __LOOP

    ; ld hl, (hl)
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    
    ; ret if NULL
    ld a, h
    or l
    ret z

    ld c, (hl)
    inc hl
    ld b, (hl)

__LOOP:
    inc hl
    ld a, b
    or c
    ret z

    ld a, (hl)
    dec bc

    cp 'A'
    jp c, __LOOP ; If a < 'a' NEXT
    cp 91  ; 'Z' + 1
    jp nc, __LOOP ; If a > 'z' NEXT

    set 5,(hl)
    jp __LOOP
    
    ENDP

    end asm
end sub


' ----------------------------------------------------------------
' function Lcase(ByVal b$)
'
' - Returns a copy of b$ converted to lowercase
' ----------------------------------------------------------------
function lcase(ByVal s$ as String) as String
    lcase2(s$)
    return s$
end function



' ----------------------------------------------------------------
' function ltrim(ByVal s$, rep$)
'
' Returns a copy of s$, removing all occurrences of rep$ on the
' left side (beginning) of s$. For example:
' ltrim(": Hello world", ": ") returns "Hello World"
' ----------------------------------------------------------------
function ltrim(ByVal s$ as String, ByVal rep$ as String) as String
    DIM i as Uinteger = 0
    DIM d, l2 as Uinteger
    DIM l as Uinteger = len(rep$)

    if not l then return s$

    d = l - 1
    l2 = len(s$)

    while i < l2 and rep = s(i to i + d)
        i = i + l
    end while

    return s$(i to)
end function



' ----------------------------------------------------------------
' function rtrim(ByVal s$, rep$)
'
' Returns a copy of s$, removing all occurrences of rep$ on the
' right side (ending) of s$. For example:
' rtrim("Hello world. ", ". ") returns "Hello World"
' ----------------------------------------------------------------
function rtrim(ByVal s$ as String, ByVal rep$ as String) as String
    DIM i as Integer
    DIM d, l2 as Uinteger
    DIM l as Uinteger = len(rep$)

    l2 = len(s$)
    if not l or l2 < l then return s$

    d = l - 1
    i = l2 - 1

    while i >= d and rep = s(i - d to i)
        i = i - l
    end while

    if i < 0 then return ""

    return s$(to i)
end function



' ----------------------------------------------------------------
' function trim(ByVal s$, rep$)
'
' Returns a copy of s$, removing all occurrences of rep$ on the
' left and right side (ending) of s$. For example:
' rtrim(";.;.Hello world;.;.", ";.") returns "Hello World"
' ----------------------------------------------------------------
function trim(ByVal s$ as String, ByVal rep$ as String) as String
    return ltrim(rtrim(s$, rep$), rep$)
end function


' ----------------------------------------------------------------
' function isdigit(ByVal s$)
'
' Returns not 0 if the first element of s$ is a digit,
' or 0 otherwise.
' For example:
' isdigit("a") returns 0, isdigit("2") returns 1
' ----------------------------------------------------------------
function isdigit(ByVal s$ as String) as ubyte
    dim asc_key as ubyte = code( s$( 0 ) )
    
    return asc_key >= code( "0" ) _
       and asc_key <= code( "9" )
end function


' ----------------------------------------------------------------
' function isletter(ByVal s$)
'
' Returns not 0 if the first element of s$ is a letter,
' or 0 otherwise.
' For example:
' isletter("0") returns 0, isletter("a") returns 1
' ----------------------------------------------------------------
function isletter(ByVal s$ as String) as ubyte
    dim asc_key as ubyte = code( s$( 0 ) )
    
    return ( asc_key >= code( "a" )   _
         and asc_key <= code( "z" ) ) _
        or ( asc_key >= code( "A" )   _
         and asc_key <= code( "Z" ) )
end function


#undef __MAX_LEN__

#pragma pop(string_base)
#pragma pop(case_insensitive)


#endif      ' __LIBRARY_STRING__

