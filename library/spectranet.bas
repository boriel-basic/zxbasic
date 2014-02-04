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


' POSIX file flags
#define ORDONLY        $0001  'Open read only
#define OWRONLY        $0002  'Open write only
#define ORDWR          $0003  'Open read/write
#define OAPPEND        $0008  'Append to the file, if it exists (write only)
#define OCREAT         $0100  'Create the file if it doesn't exist (write only)
#define OTRUNC         $0200  'Truncate the file on open for writing
#define OEXCL          $0400  'With O_CREAT, returns an error if the file exists


' CHMOD POSIX file Mode
#define SISUID   04000o   'set user ID on execution
#define SISGID   02000o   'set group ID on execution
#define SISVTX   01000o   'sticky bit
#define SIRUSR   00400o   'read by owner
#define SIWUSR   00200o   'write by owner
#define SIXUSR   00100o   'execute/search by owner
#define SIRGRP   00040o   'read by group
#define SIWGRP   00020o   'write by group
#define SIXGRP   00010o   'execute/search by group
#define SIROTH   00004o   'read by others
#define SIWOTH   00002o   'write by others
#define SIXOTH   00001o   'execute/search by others


' Macro to convert a string to ASCIIZ
#define ASCIIZ(x)   (x + CHR$(0))


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
    ld hl, Spectranet.CLOSE
    call Spectranet.HLCALL
    End Asm 
End Function


Function FASTCALL SNETrecv(socket As ubyte, addr As uinteger, length as uinteger) as byte
    Asm
    pop hl  ; Ret address
    pop de  ; address
    pop bc  ; Length
    push hl ; Restore ret address
    ld hl, Spectranet.RECV
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
    ld hl, Spectranet.POLLFD
    call Spectranet.HLCALL
    ld a, 0
    ret z
    ld c, a
    End Asm
End Function


REM Filesystem functions


Function SNETmount(proto$, host$, source$, userid$, passwd$, mpoint as Ubyte) As Integer
    REM Convert the functions to ASCIIZ
    proto$  = ASCIIZ(proto$)
    host$   = ASCIIZ(host$)
    source$ = ASCIIZ(source$)
    userid$ = ASCIIZ(userid$)
    passwd$ = ASCIIZ(passwd$)

    DIM buffer(4) as Uinteger
    DIM ix as UInteger

    buffer(0) = PEEK(Uinteger, @proto)
    buffer(1) = PEEK(Uinteger, @host)
    buffer(2) = PEEK(Uinteger, @source)
    buffer(3) = PEEK(Uinteger, @userid)
    buffer(4) = PEEK(Uinteger, @passwd)

    ix = @buffer(0)

    Asm
        push ix     ; Must be restored upon return
        push hl
        pop ix
        ld a, (ix+15)
        call Spectranet.MOUNT
        pop ix
    End Asm
End Function


Function FASTCALL SNETumount(mpoint as UByte) As UInteger
    Asm
        call Spectranet.UMOUNT
    End Asm
End Function


' -----------------------------------------------------------
' Filesystem functions (fopen, fclose, fread, fwrite, fseek)
' -----------------------------------------------------------


' -----------------------------------------------------------
' Opens a file and returns its handle. -1 on Error
'
' Example:
'           f = SNETopen(3, "myfile.bin", 
' -----------------------------------------------------------
Function SNETfopen(mpoint as Ubyte, fname$, mode as UInteger, flags as Uinteger) As Byte
    DIM addrOfFname as Uinteger
    fname$ = ASCIIZ(fname$)
    addrOfFname = @fname$    
    Asm
        ld a, (ix + 5)      ; mount point
        ld c, (ix + 8)
        ld b, (ix + 9)      ; bc = file mode
        ld e, (ix + 10)
        ld d, (ix + 11)     ; de = flags
        call Spectranet.OPEN
    End Asm
End Function


Function FASTCALL SNETfread(fhandle as Ubyte, addr as Uinteger, size as Uinteger) As Byte
    Asm
        pop hl    ; ret address
        pop de
        pop bc
        push hl
        call Spectranet.READ
        ret c
        xor a     ; Ensures A = 0 on success
    End Asm
End Function


Function FASTCALL SNETfwrite(fhandle as Ubyte, addr as Uinteger, size as Uinteger) As Byte
    Asm
        pop hl    ; ret address
        pop de
        pop bc
        push hl
        ex de, hl ; HL = address to write
        call Spectranet.WRITE
        ret c
        xor a     ; Ensures A = 0 on success
    End Asm
End Function


Function FASTCALL SNETfclose(fhandle as Ubyte) As Byte
    Asm
        call Spectranet.CLOSE
        ret c
        xor a     ; Ensures A = 0 on success
    End Asm
End Function



#require "spectranet.inc"
#require "free.asm"

#pragma pop(case_insensitive)
#endif


