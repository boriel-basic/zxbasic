'(c)2016-2017 Miguel Angel Rodriguez Jodar
'Part of ESXDos example programs.
'Compile with -tBa
'Released under GPLv3 license

'This program makes a slideshow with the contents of all SCR files on a directory

#include <esxdos.bas>

#pragma string_base = 0

Dim dhandle as Uinteger         'directory handle for OpenDir, etc
Dim cwd$, filename$ as String   'current directory and current entry filename
Dim fattr as UByte              'attributes for current entry file
Dim fhandle as Byte             'file handle to open and read a SCR file

Border 0: paper 0: Cls
cwd$ = ESXDosGetCwd  'current directory

Again:
dhandle = ESXDosOpenDir (cwd$)  'open directory
if dhandle = 0 then
  print "Directory ";cwd$;" couldn't be opened"
else
  while ESXDosReadDentry (dhandle) <> 0    'while there are entries in this directory...
    fattr = ESXDosGetDentryAttr (dhandle)  'retrieve attributes for current entry
    if not (fattr band FATTR_DIR) then     'if it is not a directory...
      filename$ = ESXDosGetDentryFilename (dhandle)   'get its name
      if filename$(LEN filename$-4 TO) = ".SCR" then  'if it's ended in .SCR
        fhandle = ESXDosOpen (filename$, EDOS_FMODE_READ)   'go open it
        if fhandle <> -1 then                               'if it could been opened
          ESXDosRead (fhandle, 16384, 6912)                 'dump its contents to the screen
          ESXDosClose (fhandle)                             'and close it
          Pause 150                                         '3 seconds to admire ZX Spectrum graphics art
        end if
      end if
    end if
  end while                                'moving on next directory entry
  ESXDosCloseDir (dhandle)                 'no more entries, close directory
  Goto Again                               'and start over again
end if
