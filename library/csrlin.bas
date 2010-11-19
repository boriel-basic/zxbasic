' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_CSRLIN__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_CSRLIN__

#pragma push(case_insensitive)
#pragma case_insensitive = true

' ----------------------------------------------------------------
' function csrlin()
' 
' Returns:
'	A byte containing the current ROW printing position
' ----------------------------------------------------------------
function FASTCALL csrlin as ubyte
	dim maxy as ubyte at 23683: REM 'Max ROW position + 1 (default 25)
	dim ny as ubyte at 23689  : REM current maxy - row screen position

	if ny = 0 then return 0: end if

	return maxy - ny
end function

#pragma pop(case_insensitive)


#endif

