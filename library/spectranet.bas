' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_SPECTRANET__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SPECTRANET__
#pragma push(case_insensitive)
#pragma case_insensitive = TRUE


Function FASTCALL SNETsocket(stype As ubyte) As byte
    Asm
    ld c, a  ; c = type
    ld hl, Spectranet.SOCKET
    call Spectranet.HLCALL
    End Asm
End Function


Function FASTCALL SNETbind(socket as ubyte, port As uinteger) As byte
    Asm
    pop hl
    ex (sp), hl
    ex de, hl  ; HL = port
    ld hl, Spectranet.BIND
    call Spectranet.HLCALL
    End Asm
End Function


Function FASTCALL SNETlisten(socket As ubyte) As byte
    Asm
    ld hl, Spectranet.LISTEN
    call Spectranet.HLCALL
    End Asm
End Function


Function FASTCALL SNETaccept(socket As ubyte) As byte
    Asm
    ld hl, Spectranet.ACCEPT
    call Spectranet.HLCALL
    End Asm
End Function


Function FASTCALL SNETconnect(socket As ubyte, ip$, port As uinteger) As byte
    Asm
    pop hl  ; ret address
    pop de  ; string containing the IP in CODE format. e.g. 10.0.0.1 = chr$(10, 0, 0, 1)
    pop bc  ; port
    push hl  ; Ret address restored; hl = port
    ld hl, Spectranet.CONNECT
    push de ; Used later to free the string
    inc de
    inc de
    call Spectranet.HLCALL
    pop hl
    ex af, af'
    call __MEM_FREE
    ex af, af'
    End Asm
End Function


Function FASTCALL SNETclose(socket As ubyte) As byte
    Asm
    ld hl, CLOSE
    call Spectranet.HLCALL
    End Asm 
End Function


Function FASTCALL SNETrecv(socket As ubyte, addr As uinteger, length as uinteger) as byte
    Asm
    pop hl  ; Ret address
    pop de  ; address
    pop bc  ; Length
    push hl ; Restore ret address
    ld hl, RECV
    call Spectranet.HLCALL
    End Asm 
End Function


Function FASTCALL SNETsend(socket As ubyte, addr As uinteger, length as uinteger) as byte
    Asm
    pop hl  ; Ret address
    pop de  ; address
    pop bc  ; Length
    push hl ; Restore ret address
    ld hl, Spectranet.SEND
    call Spectranet.HLCALL
    End Asm 
End Function


Function FASTCALL SNETpollfd(socket As ubyte) as ubyte
    Asm
    ld hl, POLLFD
    call Spectranet.HLCALL
    ld a, 0
    ret z
    ld c, a
    End Asm
End Function


#require "spectranet.inc"
#require "free.asm"

#pragma pop(case_insensitive)
#endif
