' ----------------------------------------------------------------
' This file is released under the GPL v3 License
'
' This library is to be included automatically if the user
' specifies -Z or --sinclar parameter.
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_SINCLAIR__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SINCLAIR__

REM This library includes other classic Sinclair ZX Spectrum Routines

#include once <attr.bas>
#include once <point.bas>
#include once <screen.bas>


REM This is not the original Sinclair INPUT, but better than nothing
#include once <input.bas>

REM This is to initialize USR "a" to a memory heap space
#include once <alloc.bas>

REM Now updates UDG system var to new UDG memory zone
POKE Uinteger 23675, allocate(21 * 8) : REM 8 bytes per UDG (21 total)

#endif

