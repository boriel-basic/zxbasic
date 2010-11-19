' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_POS__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_POS__

#pragma push(case_insensitive)
#pragma case_insensitive = true

REM Put your code here.

' ----------------------------------------------------------------
' function pos()
'
' Returns:
' 	Current COLUMN print position
' ----------------------------------------------------------------
function FASTCALL pos as ubyte
	dim maxx as ubyte at 23682: REM 'Max COL position + 1 (default 33)
	dim nx as ubyte at 23688  : REM current maxx - column screen position

	if nx = 0 then return 0: end if

	return maxx + 1 - nx
end function

#pragma pop(case_insensitive)


#endif

