'(c)2016-2017 Miguel Angel Rodriguez Jodar
'Part of ESXDos example programs.
'Compile with -tBa
'Released under GPLv3 license

'This program shows how to list a directory

#include <esxdos.bas>
#include <csrlin.bas>

Dim dhandle as Uinteger
Dim cwd$ as String
Dim i,fattr as UByte

Cls
cwd$ = ESXDosGetCwd
dhandle = ESXDosOpenDir (cwd$)
if dhandle = 0 then
  print "Directory ";cwd$;" couldn't be opened"
else
  print "Directory of ";cwd$
  while ESXDosReadDentry (dhandle) <> 0
    fattr = ESXDosGetDentryAttr (dhandle)
    print ESXDosGetDentryFilename (dhandle);

    if fattr band FATTR_DIR then
      print tab 16;"<DIR>"
    else
      print tab 16;ESXDosGetDentryFilesize (dhandle)
    end if

    if csrlin = 23 then
      pause 0
      cls
    end if

  end while
  ESXDosCloseDir (dhandle)
end if
