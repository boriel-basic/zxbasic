' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' Contributed by @Winston, @Guesser, @Ardentcrest
'
' Thanks a lot for your help! :))
' ----------------------------------------------------------------

#ifndef __LIBRARY_SPECTRANET__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SPECTRANET__
#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

#include <string.bas>


' POSIX file flags
#define O_RDONLY        $0001  'Open read only
#define O_WRONLY        $0002  'Open write only
#define O_RDWR          $0003  'Open read/write
#define O_APPEND        $0008  'Append to the file, if it exists (write only)
#define O_CREAT         $0100  'Create the file if it doesn't exist (write only)
#define O_TRUNC         $0200  'Truncate the file on open for writing
#define O_EXCL          $0400  'With O_CREAT, returns an error if the file exists


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


#define SEEK_SET 0x00
#define SEEK_CUR 0x01
#define SEEK_END 0x02


' Macro to convert a string to ASCIIZ
#define ASCIIZ(x)   (x + CHR$(0))
' Where to store FILE op errors
#define ERR_NR 23610


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


' -----------------------------------------------------------
' Reads a memory address (16 bit) from paged memory
' -----------------------------------------------------------
Function FASTCALL SNETpeekUinteger(addr as Uinteger) As UInteger
    Asm
        ex de, hl
        ld hl, Spectranet.PAGEIN
        call Spectranet.HLCALL
        ex de, hl
        ld e, (hl)
        inc hl
        ld d, (hl)
        ld hl, Spectranet.PAGEOUT
        call Spectranet.HLCALL
        ex de, hl
    End Asm
End Function


' -----------------------------------------------------------
' Filesystem functions (fopen, fclose, fread, fwrite, fseek)
' -----------------------------------------------------------

' -----------------------------------------------------------
' Mounts a remote filesystem. Returns session number.
' 
' Example:
'     SNETmount(0, "tnfs", "vexed4.alioth.net", "", "", "")
' -----------------------------------------------------------
Function SNETmount(mpoint as Ubyte, proto$, host$, source$, userid$, passwd$) As Integer
    REM Convert the functions to ASCIIZ
    proto$  = ASCIIZ(proto$)
    host$   = ASCIIZ(host$)
    source$ = ASCIIZ(source$)
    userid$ = ASCIIZ(userid$)
    passwd$ = ASCIIZ(passwd$)

    DIM buffer(4) as Uinteger
    DIM ix as UInteger

    buffer(0) = PEEK(Uinteger, @proto) + 2
    buffer(1) = PEEK(Uinteger, @host) + 2
    buffer(2) = PEEK(Uinteger, @source) + 2 
    buffer(3) = PEEK(Uinteger, @userid) + 2
    buffer(4) = PEEK(Uinteger, @passwd) + 2

    ix = @buffer(0)  ' Useless, but will allow to calculate HL
    Asm
        ld a, (ix + 5)
        push ix     ; Must be restored upon return
        push hl
        pop ix
        ld hl, Spectranet.MOUNT
        call Spectranet.HLCALL
        pop ix
    End Asm
End Function


' -----------------------------------------------------------
' Returns current mount point
' -----------------------------------------------------------
Function SNETcurrMPoint() as Byte
    print inK 7; paper 2; CAST(Ubyte, SNETpeekUinteger(0x1001))
    return SNETpeekUinteger(0x1001)
End Function


' -----------------------------------------------------------
' Changes the current mount point
' -----------------------------------------------------------
sub FASTCALL SNETsetmountpt(mpoint)
    Asm
    ld hl, Spectranet.SETMOUNTPOINT 
    call Spectranet.HLCALL
    End Asm
End sub


' -----------------------------------------------------------
' Umounts a previously mounted filesystem
'
' Example:
'     SNETumount(0)
' -----------------------------------------------------------
Function FASTCALL SNETumount(mpoint as UByte) As UInteger
    Asm
        ld hl, Spectranet.UMOUNT
        call Spectranet.HLCALL
    End Asm
End Function


' -----------------------------------------------------------
' Opens a file and returns its handle. -1 on Error
' This function will be changed to copycat the C style,
' like: SNETfopen(0, "myfile", "rb"). Not yet.
' Returns the file handle (byte). -1 On error.
'
' Example:
'    Opens a file for read. The 1st one is the mount point.
'    The last parameter is ignored (0)
'    fhandle = SNETfopen(0, "myfile.bin", O_RDONLY, 0)
'
'    Opens a file for writing (creates the file). The last parameter
'    is the chmod.
'    fhandle = SNETopen(0, "newfile.blah", O_CREAT | O_WRONLY, 0666o)
' -----------------------------------------------------------
Function SNETopen(mpoint as Ubyte, fname$, flags as UInteger, chmod as Uinteger) As Byte
    DIM addrOfFname as Uinteger
    fname$ = ASCIIZ(fname$)
    addrOfFname = PEEK(Uinteger, @fname$) + 2    
    Asm
        ld a, (ix + 5)      ; mount point
        ld e, (ix + 8)
        ld d, (ix + 9)      ; de = flags (ORDONLY, etc...)
        ld c, (ix + 10)
        ld b, (ix + 11)     ; bc = chmod mode
        
        push ix
        ld ix, Spectranet.OPEN
        call Spectranet.IXCALL
        pop ix
    End Asm
End Function


' -----------------------------------------------------------
' Reads content from a file, an places it at a memory address.
' Returns the effectively number of bytes read.
' 
' Example:
'    Loading a binary screen (no .TAP file, just raw bytes)
'    SNETfread(f, 16384, 6912)
' -----------------------------------------------------------
Function FASTCALL SNETfread(fhandle as Ubyte, addr as Uinteger, size as Uinteger) As Uinteger
    Asm
        pop hl    ; ret address
        pop de
        pop bc
        push hl
        ld hl, Spectranet.READ
        call Spectranet.HLCALL
        ld h, b   ; BC = Num. of bytes read if no Carry
        ld c, l
        ret nc
        ld (ERR_NR), a
    End Asm
End Function


' -----------------------------------------------------------
' Write content from a memory address into a file
' Returns the effectively number of bytes written.
' 
' Example:
'    Saving screen into a binary file (no .TAP file, just raw bytes)
'    SNETfwrite(f, 16384, 6912)
' -----------------------------------------------------------
Function FASTCALL SNETfwrite(fhandle as Ubyte, addr as Uinteger, size as Uinteger) As Uinteger
    Asm
        pop hl    ; ret address
        pop de    ; addr
        pop bc    ; size
        push hl   ; ret address
        ex de, hl ; HL = address to write
        push ix
        ld ix, Spectranet.WRITE
        call Spectranet.IXCALL
        pop ix
        ld h, b
        ld c, l
        ret nc
        ld (ERR_NR), a
    End Asm
End Function



' -----------------------------------------------------------
' Mimics C fopen. Opens a file for reading or writing, 
' returning its handle on success or -1 on error.
' -----------------------------------------------------------
Function SNETfopen(mpoint as Ubyte, fname$, mode$) as Byte
    dim flags As Uinteger = 0
    if inStr(mode$, "r")
        flags = flags | O_RDONLY
    end if
    if inStr(mode$, "w")
        flags = flags | O_CREAT | O_TRUNC | O_WRONLY
    end if
    if inStr(mode$, "a")
        flags = flags | O_APPEND | O_CREAT | O_WRONLY
    end if
    if inStr(mode$, "+")
        flags = flags | O_RDWR
    end if

    return SNETopen(mpoint, fname$, flags, 666o) 
    
End Function


' -----------------------------------------------------------
' Closes an open file.
'
' Example:
'    SNETfclose(f)
' -----------------------------------------------------------
Function FASTCALL SNETfclose(fhandle as Ubyte) As Byte
    Asm
        ld hl, Spectranet.CLOSE
        call Spectranet.HLCALL
        ret c
        xor a     ; Ensures A = 0 on success
    End Asm
End Function


' -----------------------------------------------------------
' Changes the current file read/write position.
'
' Example:
'      - Jumps to the end of file
'     SNETfseek(f, SEEK_END, 0)
' -----------------------------------------------------------
Function FASTCALL SNETfseek(fhandle as Ubyte, op as Ubyte, pos as ULong) as Byte
    Asm
        pop hl  ;  Return address
        ; pop af ; Not done. FASTCALL passes always the 1s parameter
        pop bc  ;  Bytes comes in the high part, so B. 
        ld c, b ;  C = operation
        pop de  ;  Low Ulong 32
        ex (sp), hl  ; Push ret address back, hl = high part
        ex de, hl  ; Now DEHL = Ulong 32
        push ix
        ld ix, Spectranet.LSEEK
        call Spectranet.IXCALL
        pop ix
        ret c
        xor a      ; Ensures A = 0 on success
    End Asm
End function


' -----------------------------------------------------------
' Deletes a file.
'
' Example:
'     SNETunlink("myfile.dat")
' -----------------------------------------------------------
Function SNETunlink(fname$) AS Byte
    fname$ = ASCIIZ(fname$)
    DIM addr as Uinteger
    addr = PEEK(Uinteger, @fname) + 2
    Asm
        PROC
        LOCAL CONT
        push ix
        ld ix, Spectranet.UNLINK
        call Spectranet.IXCALL
        pop ix
        jr c, CONT 
        xor a      ; Ensures A = 0 on success
    CONT:
        ENDP
    End Asm 
End Function


#undef ASCIIZ
#undef ERR_NR

#require "spectranet.inc"
#require "free.asm"

#pragma pop(case_insensitive)
#endif


