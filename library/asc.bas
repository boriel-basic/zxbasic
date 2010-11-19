
#ifndef __LIBRARY_ASC__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_ASC__

REM The asc function, as described in FREEBASIC

function asc(s AS STRING, x AS UINTEGER) AS UBYTE
	if len(s) <= x then
		return 0
	end if

	return code s(x TO x)
end function

#endif

