' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
'
' Replace <NAME> with your desired identifier. I.e. for PAUSE
' use __LIBRARY_PAUSE__ (see pause.bas code)
'
' Suggestions:
' 	* Be methodic. Use something MEANINGFUL
'	* Use *long* names to avoid collision with other developers.
'	  Names can be as long as you want, and are only used 3 times.
' ----------------------------------------------------------------

#ifndef __LIBRARY_<NAME>__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_<NAME>__

REM Put your code here.

' ----------------------------------------------------------------
' function NAME
' 
' Parameters: 
'     x <explanation>
'     y <explanation>
'
' Returns:
'     <explanation> (When nothing to return, use SUB instead)
' ----------------------------------------------------------------
function NAME

...
...

end function


' ----------------------------------------------------------------
' If your function above uses other functions in
' your module, the following name scheme is suggested
' to avoid collision with other developers functions
' ----------------------------------------------------------------

function PRIVATE<NAME>XXXX

...
...

end function



#endif

