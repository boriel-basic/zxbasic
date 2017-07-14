'(c)2016-2017 Miguel Angel Rodriguez Jodar
'Part of ESXDos example programs.
'Compile with -tBa
'Released under GPLv3 license

'This program draws the filesystem structure as a tree (like the TREE command on MS-DOS)

#include <esxdos.bas>
#include <csrlin.bas>

DECLARE Function GenerateSpaces (ByVal n as Byte) as string

Cls
DirectoryTree ("/")
end

Sub DirectoryTree (ByVal path$ as string)
  Dim cwd$ as string

  cwd$ = ESXDosGetCwd
  print path$

  DisplayDirectoryTree (path$, GenerateSpaces(LEN path$ -2)+"|")
  ESXDosChDir (cwd$)
End Sub

Sub DisplayDirectoryTree (ByVal path$ as string, ByVal graph$ as string)
  Dim h as UInteger
  Dim entry$ as string
  Dim fattr as UByte

  ESXDosChDir (path$)
  h = ESXDosOpenDir (".")

  if h = 0 then
    return
  end if

  while ESXDosReadDentry(h) <> 0
    fattr = ESXDosGetDentryAttr(h)  'retrieve attributes for current entry
    if fattr band FATTR_DIR then
      entry$ = ESXDosGetDentryFilename(h)
      if entry<>"." and entry<>".." then
        print graph$;"-";entry$
        TestScroll
        DisplayDirectoryTree (entry$, graph$+GenerateSpaces(LEN entry$)+"|")
        ESXDosChDir ("..")
      end if
    end if
  end while
  ESXDosCloseDir(h)
End Sub

Sub TestScroll
  Dim tecla$ as string

  if csrlin = 22 then
    print at 23,0;"scroll?"
    Pause 0
    tecla$ = inkey$
    if tecla$ = "n" or tecla$ = "N" or tecla$ = " " then
      ThrowError(21)  'L Break...
    end if
    Cls
  end if
End Sub

Function GenerateSpaces (ByVal n as Byte) as string
  if n < 1 then
    return ""
  else
    return "                        "(to n-1)
  end if
End Function

Sub ThrowError (ByVal errcode as UByte)
  poke EDOS_ERR_NR,errcode-1
  Asm
    Proc
      Local parche
      ld a,(EDOS_ERR_NR)
      ld (parche),a
      rst 8
parche: db 0
    endp
  end asm
End Sub