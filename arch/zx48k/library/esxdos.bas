' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2017
' by Miguel Angel Rodriguez Jodar (mcleod_ideafix)
' and Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' ESXDOS file access usage
' ----------------------------------------------------------------

#ifndef __LIBRARY_ESXDOS__
REM Avoid recursive / multiple inclusion
#define __LIBRARY_ESXDOS__

#include <alloc.bas>
#include <hex.bas>

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
#define F_OPENDIR	(FSYS_BASE+11)
#define F_READDIR	(FSYS_BASE+12)
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

#define FATTR_RDONLY   1
#define FATTR_HIDDEN   2
#define FATTR_SYSTEM   4
#define FATTR_VOLUME   8
#define FATTR_DIR     16
#define FATTR_ARCHIVE 32

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
    poke EDOS_ERR_NR,255

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
    poke EDOS_ERR_NR,255

    Asm
    ;FASTCALL implies handle is already in A register
    ld hl, EDOS_ERR_NR
    ld (hl), 255  ; sets 255 = OK
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
    ld (EDOS_ERR_NR),a
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
    ld hl, EDOS_ERR_NR
    ld (hl), 255  ; sets 255 = OK
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
    ld (EDOS_ERR_NR),a
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
'    it currently uses a portion of the heap
' ----------------------------------------------------------------
Function ESXDosGetCwd as String
    Dim cwd$ as String
    Dim addr as Uinteger

    Asm
    proc
      local NotNull

      xor a
      rst 8
      db M_GETSETDRV      ;Default drive in A
      push af             ;Preserve drive
      ld bc,256           ;reserve 256 bytes from heap
      call __MEM_ALLOC    ;call to allocate
      ld a,h
      or l
      jr nz,NotNull
      rst 8
      db 3                ;4 Out of memory
NotNull:
      pop af              ;restore drive
      ld (ix-4),l         ;store address of alloced block into addr variable
      ld (ix-3),h
      push ix
      push hl
      pop ix
      rst 8
      db F_GETCWD
      pop ix
    endp
    End Asm

    cwd$ = ""
    While peek(addr)<>0                'Read ASCIIZ string from the heap
      cwd$ = cwd$ + chr$ (peek(addr))  'and concatenate each character to a BASIC string
      addr = addr + 1
    End While

    deallocate (addr)  'free memory block allocated from the heap in the ASM block

    return cwd$
End Function


' ----------------------------------------------------------------
' Function ESXDosOpenDir
'
' Parameters:
'    path: string containing the directory path to open
'
' Returns:
'    a handle to the opened directory, or 0 if error
'
' Remarks:
'    it currently uses a portion of the heap that must be
'    deallocated by calling ESXDosCloseDir
' ----------------------------------------------------------------
Function ESXDosOpenDir (ByVal path as String) as UInteger
    Dim handle as UInteger

    poke EDOS_ERR_NR,255
    handle = 65535
    if path = "" then
      return 0
    end if

    Asm
    Proc
      local NotNull
      local HandleOK
      Local ExitFunction

      xor a
      ld bc,32            ;reserve 32 bytes from heap
      call __MEM_ALLOC    ;call to allocate
      ld a,h
      or l
      jr nz,NotNull
      rst 8
      db 3                ;4 Out of memory

NotNull:
      ld (ix-2),l
      ld (ix-1),h

      push hl
      ex de,hl            ;
      ld l,(ix+4)         ;
      ld h,(ix+5)         ; copy string from
      ld c,(hl)           ; BASIC to heap and
      inc hl              ; convert it to ASCIIZ
      ld b,0              ;
      inc hl              ;
      ldir                ;
      xor a               ;
      ld (de),a           ;
      pop hl

      rst 8
      db M_GETSETDRV      ;Default drive in A

      ld l,(ix-2)
      ld h,(ix-1)
      ld b,0
      push ix
      push hl
      pop ix
      rst 8
      db F_OPENDIR
      pop ix
      jr nc,HandleOK

      ld (EDOS_ERR_NR),a
      call __MEM_FREE     ;deallocate mem
      ld (ix-2),0
      ld (ix-1),0
      jr ExitFunction

HandleOK:
      ld l,(ix-2)
      ld h,(ix-1)
      ld (hl),a           ;store handle into offset 0 of memory block

ExitFunction:
    endp
    End Asm

    return handle
End Function



' ----------------------------------------------------------------
' Sub ESXDosCloseDir
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' ----------------------------------------------------------------
Sub ESXDosCloseDir (ByVal handle as UInteger)
  if (handle <> 0) then
    ESXDosClose (peek (handle)) 'close directory handle
    deallocate (handle)         'deallocate memory buffer used by opendir/readdir
  end if
End Sub



' ----------------------------------------------------------------
' Function ESXDosReadDentry
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Returns:
'    0 if there was no more entries on this directory, or non 0 if a
'    new entry was retrieved
'
' ----------------------------------------------------------------
Function ESXDosReadDentry (ByVal handle as UInteger) as Byte
  poke EDOS_ERR_NR,255
  if handle = 0 then
    return 0
  end if

  Asm
    Proc
      local read_ok

      ld l,(ix+4)  ;
      ld h,(ix+5)  ; HL = block of memory where OpenDir stored handle
      ld a,(hl)
      inc hl

      push ix
      push hl
      pop ix
      rst 8
      db F_READDIR
      pop ix
      jr nc,read_ok
      ld (EDOS_ERR_NR),a
      xor a
read_ok:
    Endp
  End Asm

End Function



' ----------------------------------------------------------------
' Function ESXDosGetDentryFilename
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Returns:
'    a string containing the filename of the directory entry retrieved
'    in the last call to ESXDosReadDentry
'
' ----------------------------------------------------------------
Function ESXDosGetDentryFilename (ByVal handle as UInteger) as String
  Dim filename$ as String

  filename$ = ""
  if handle = 0 then
    return ""
  end if

  handle = handle + 2  'jump over ESXDOS handle and file attributes
  while peek(handle) <> 0
    filename$ = filename$ + chr$(peek(handle))
    handle = handle + 1
  end while
  return filename$
End Function



' ----------------------------------------------------------------
' Function ESXDosGetDentryAttr
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Returns:
'    an unsigned byte containing the file attributes of the directory entry
'    retrieved in the last call to ESXDosReadDentry
'
' ----------------------------------------------------------------
Function ESXDosGetDentryAttr (ByVal handle as UInteger) as UByte
  if handle = 0 then
    return 0
  end if

  return peek (handle+1)
End Function



' ----------------------------------------------------------------
' Function ESXDosGetDentryFilesize
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Returns:
'    an unsigned long value containing the file size of the directory
'    entry retrieved in the last call to ESXDosReadDentry
'
' ----------------------------------------------------------------
Function ESXDosGetDentryFilesize (ByVal handle as UInteger) as ULong
  if handle = 0 then
    return 0
  end if

  Asm
    Proc
      Local ParseString

      ld l,(ix+4)
      ld h,(ix+5)
      inc hl  ;skip over ESXDOS directory handle

ParseString:
      inc hl  ;skip over file attr (or over a character of the filename)
      ld a,(hl)
      or a
      jr nz,ParseString
      ld de,5
      add hl,de  ;skip over null byte and timestamp
      ld c,(hl)
      inc hl
      ld b,(hl)
      inc hl
      ld e,(hl)
      inc hl
      ld d,(hl)
      ld h,b
      ld l,c
    endp
  End Asm
End Function



' ----------------------------------------------------------------
' Function ESXDosChDir
'
' Parameters:
'    path: string containing the directory path to change to
'
' ----------------------------------------------------------------
Sub ESXDosChDir (ByVal path as String)
    Dim handle as UInteger

    poke EDOS_ERR_NR,255
    if path = "" then
      return
    end if

    Asm
    Proc
      local NotNull
      local HandleOK

      xor a
      ld bc,256           ;reserve 256 bytes from heap
      call __MEM_ALLOC    ;call to allocate
      ld a,h
      or l
      jr nz,NotNull
      rst 8
      db 3                ;4 Out of memory

NotNull:
      push hl
      ex de,hl            ;
      ld l,(ix+4)         ;
      ld h,(ix+5)         ; copy string from
      ld c,(hl)           ; BASIC to heap and
      inc hl              ; convert it to ASCIIZ
      ld b,0              ;
      inc hl              ;
      ldir                ;
      xor a               ;
      ld (de),a           ;

      rst 8
      db M_GETSETDRV      ;Default drive in A

      pop hl
      push hl
      push ix
      push hl
      pop ix
      rst 8
      db F_CHDIR
      pop ix
      jr nc,HandleOK
      ld (EDOS_ERR_NR),a
HandleOK:
      pop hl
      call __MEM_FREE     ;deallocate mem
    endp
    End Asm

End Sub


' ----------------------------------------------------------------
' Function ESXDosTellDir
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Returns:
'    an unsigned long value which is the directory entry # to be retrieved
'    on the next call to ESXDosReadDentry
'
' ----------------------------------------------------------------
Function ESXDosTellDir (ByVal handle as UInteger) as ULong

  poke EDOS_ERR_NR,255
  if handle = 0 then
    return 0
  end if

  Asm
    Proc
      local read_ok,divide_by_32

      ld l,(ix+4)  ;
      ld h,(ix+5)  ; HL = block of memory where OpenDir stored handle
      ld a,(hl)

      push ix
      rst 8
      db F_TELLDIR
      pop ix
      jr nc,read_ok
      ld (EDOS_ERR_NR),a
      ld hl,0
read_ok:
      ld h,d   ;
      ld l,e   ; BCDE -> DEHL for ZX Basic
      ld d,b   ;
      ld e,c   ;

      ld b,5
divide_by_32:           ;
      srl d             ;
      rr e              ; DEHL / 32
      rr h              ;
      rr l              ;
      djnz divide_by_32
    Endp
  End Asm

End Function


' ----------------------------------------------------------------
' Sub ESXDosSeekDir
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'    entry: ULong containing the directory entry # to seek to.
'
' ----------------------------------------------------------------
Sub ESXDosSeekDir (ByVal handle as UInteger, ByVal entry as ULong)
  poke EDOS_ERR_NR,255
  if handle = 0 then
    return
  end if

  Asm
    Proc
      local read_ok

      ld l,(ix+4)  ;
      ld h,(ix+5)  ; HL = block of memory where OpenDir stored handle
      ld a,(hl)

      ld e,(ix+6)
      ld d,(ix+7)
      ld l,(ix+8)
      ld h,(ix+9)

      ld b,5
multiply_by_32:
      sla l   ;
      rl h    ; Multiply DEHL by 32
      rl e    ;
      rl d    ;
      djnz multiply_by_32
      ld b,h    ;
      ld c,l    ; Offset is now at BCDE

      ld l,0    ; Just in case this is using L as in F_SEEK (to-do)
      push ix
      rst 8
      db F_SEEKDIR
      pop ix
      jr nc,read_ok
      ld (EDOS_ERR_NR),a
read_ok:
    Endp
  End Asm

End Sub


' ----------------------------------------------------------------
' Sub ESXDosRewindDir
'
' Parameters:
'    handle: UInteger containing a valid handle returned by ESXDosOpenDir
'
' Remarks:
'    Functionally equivalent to ESXDosSeekDir (handle, 0)
'
' ----------------------------------------------------------------
Sub ESXDosRewindDir (ByVal handle as UInteger)
  poke EDOS_ERR_NR,255
  if handle = 0 then
    return
  end if

  Asm
    Proc
      local read_ok

      ld l,(ix+4)  ;
      ld h,(ix+5)  ; HL = block of memory where OpenDir stored handle
      ld a,(hl)

      push ix
      rst 8
      db F_REWINDDIR
      pop ix
      jr nc,read_ok
      ld (EDOS_ERR_NR),a
read_ok:
    Endp
  End Asm
End Sub

#endif
