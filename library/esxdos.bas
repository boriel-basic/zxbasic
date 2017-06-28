' ----------------------------------------------------------------
' This file is released under the GPL v3 License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file

' ESXDOS file access usage
' ----------------------------------------------------------------

#ifndef __LIBRARY_ESXDOS__
REM Avoid recursive / multiple inclusion
#define __LIBRARY_ESXDOS__

' Some ESXDOS system calls
#define HOOK_BASE   128
#define MISC_BASE   (HOOK_BASE+8)
#define FSYS_BASE   (MISC_BASE+16)
#define M_GETSETDRV (MISC_BASE+1)
#define F_OPEN      (FSYS_BASE+2)
#define F_CLOSE     (FSYS_BASE+3)
#define F_READ      (FSYS_BASE+5)
#define F_WRITE     (FSYS_BASE+6)
#define F_SEEK      (FSYS_BASE+7)
#define F_GETPOS    (FSYS_BASE+8)
#define F_OPENDIR		(FSYS_BASE+11)
#define F_READDIR		(FSYS_BASE+12)
#define F_TELLDIR   (FSYS_BASE+13)
#define F_SEEKDIR   (FSYS_BASE+14)
#define F_REWINDDIR (FSYS_BASE+15)
#define F_GETCWD    (FSYS_BASE+16)
#define F_CHDIR     (FSYS_BASE+17)
#define F_MKDIR     (FSYS_BASE+18)
#define F_RMDIR     (FSYS_BASE+19)

#define EDOS_FMODE_READ       0x1 ' Read access
#define EDOS_FMODE_WRITE      0x2 ' Write access
#define EDOS_FMODE_OPEN_EX    0x0 ' Open if exists, else error
#define EDOS_FMODE_OPEN_AL    0x8 ' Open if exists, if not create
#define EDOS_FMODE_CREATE_NEW 0x4 ' Create if not exist, else error
#define EDOS_FMODE_CREATE_AL  0xc ' Create if not exist, else open and trunc

#define SEEK_START  0   ' From the beginning of file
#define SEEK_CUR    1   ' From the current position
#define SEEK_BKCUR  2   ' From the current position, backwards

#define EDOS_ERR_NR 23610

' ----------------------------------------------------------------
' function ESXDosOpen
' 
' Parameters: 
'     filename: file to open
'     mode: one of FMODE
'
' Returns:
'     File stream ID (ubyte)
'     it can be -1 on error (variable ERR_NR will contain 
'     another value with extra information)
' ----------------------------------------------------------------
Function ESXDosOpen(ByVal fname as String, ByVal mode as Ubyte) as Byte
    fname = fname + chr$ 0
    Asm 
    ld l, (ix+4)
    ld h, (ix+5)    ; fname ptr
    ld a, (ix+7)    ; mode in a
    inc hl
    inc hl
    push ix
    push hl
    push af

    xor a    
    rst 8
    db M_GETSETDRV  ; Default drive in A

    pop bc          ; Open mode in B
    pop ix          ; Uses IX for fname pointer
   
    rst 8 
    db F_OPEN 
    pop ix
    jr nc, open_ok
    ld (EDOS_ERR_NR), a
    ld a, 0FFh
open_ok:            ; returns Ubyte result form A Register
    End Asm
End Function


' ----------------------------------------------------------------
' Sub ESXDosClose
' 
' Parameters: 
'     handle: File stream ID to close
' ----------------------------------------------------------------
Sub FASTCALL ESXDosClose(ByVal handle as Byte)
    Asm
    ;FASTCALL implies handle is already in A register
    push ix
    rst 8
    db F_CLOSE
    pop ix
    End Asm
End Sub


' ----------------------------------------------------------------
' Function ESXDosWrite
' 
' Parameters:
'    handle: file handle (returned by ESXDOSOpen
'    buffer: memory address for the buffer
'    nbytes: number of bytes to write
'
' Returns:
'    number of bytes effectively written
' ----------------------------------------------------------------
Function FASTCALL ESXDosWrite(ByVal handle as Byte, _
                     ByVal buffer as UInteger, _
                     ByVal nbytes as UInteger) as Uinteger
    Asm
    ;FASTCALL implies handle is already in A register
    pop de  ; ret address
    pop hl  ; buffer address
    pop bc  ; bc <- nbytes
    push de ; put back ret address
    push ix ; saves IX for ZX Basic
    push hl
    pop ix  ; uses IX <- HL 
    rst 8h
    db F_WRITE
    jr nc, write_ok
    ld bc, -1
write_ok:
    ld h, b
    ld l, c
    pop ix  ; recovers IX for ZX Basic
    End Asm
End Function


' ----------------------------------------------------------------
' Function ESXDosRead
'
' Parameters:
'    handle: file handle (returned by ESXDOSOpen
'    buffer: memory address for the buffer
'    nbytes: number of bytes to read
'
' Returns:
'    number of bytes effectively read
' ----------------------------------------------------------------
Function FASTCALL ESXDosRead(ByVal handle as Byte, _
                     ByVal buffer as UInteger, _
                     ByVal nbytes as UInteger) as Uinteger
    Asm
    ;FASTCALL implies handle is already in A register
    pop de  ; ret address
    pop hl  ; buffer address
    pop bc  ; bc <- nbytes
    push de ; put back ret address
    push ix ; saves IX for ZX Basic
    push hl
    pop ix  ; uses IX <- HL
    rst 8h
    db F_READ
    jr nc, read_ok
    ld bc, -1
read_ok:
    ld h, b
    ld l, c
    pop ix  ; recovers IX for ZX Basic
    End Asm
End Function


' ----------------------------------------------------------------
' Sub ESXDosSeek
'
' Parameters:
'   handle: file handle
'   offset: file offset
'   position: from position, one of SEEK_ constants
' ----------------------------------------------------------------
Sub FASTCALL ESXDosSeek(ByVal handle as byte, _
                        ByVal offset as Long, _
                        ByVal position as UByte)
    Asm
    ;FASTCALL implies handle is already in A register
    pop hl  ; ret address
    pop de  ; low (word) offset part
    pop bc  ; hi (word) offset part
    ex (sp), hl  ; pop position param and put ret address back in the stack
    ld l, h ; l <- h <- position (0: start, 1: forward current, 2: back current)
    push ix ; saves IX for ZX Basic
    push hl
    pop ix  ; uses IX <- HL
    rst 8
    db F_SEEK
    pop ix  ; recovers IX for ZX Basic
    End Asm
End Sub


' ----------------------------------------------------------------
' Function ESXDosGetPos
'
' Parameters:
'    handle: file handle (returned by ESXDosOpen)
'
' Returns:
'    the current file position
' ----------------------------------------------------------------
Function ESXDosGetPos (ByVal handle as byte) as long
    Asm
    ld a,(ix+5)
    rst 8
    db F_GETPOS
    ld h,d
    ld l,e  ; BCDE -> DEHL for return
    ld d,b
    ld e,c
    End Asm
End Function


' ----------------------------------------------------------------
' Function ESXDosGetCwd
'
' Parameters:
'    None
'
' Returns:
'    the current working directory name as a string.
'
' Remarks:
'    it currently uses a portion of memory starting at address
'    23296 for temporary string storage
' ----------------------------------------------------------------
Function ESXDosGetCwd as String
    Dim cwd$ as String
    Dim addr as Uinteger

    Asm
      push ix
      xor a
      rst 8
      db M_GETSETDRV  ; Default drive in A
      ld ix,23296  ;pointer temporary storage for string returned
      rst 8
      db F_GETCWD
      pop ix
    End Asm

    addr = 23296   'start of temporary storage for ASCIIZ string returned by ESXDOS
    cwd$ = ""
    While peek(addr)<>0                'Read ASCIIZ string from 23296
      cwd$ = cwd$ + chr$ (peek(addr))  'and concatenate each character to a BASIC string
      addr = addr + 1
    End While
    return cwd$
End Function

#endif
