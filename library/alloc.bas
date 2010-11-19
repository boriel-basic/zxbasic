' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_ALLOC__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_ALLOC__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ----------------------------------------------------------------
' function malloc
'
' Allocates the requested bytes in the heap (dynamic memory) and
' returns the address (16 bit, unsigned) of the new bloc. If
' no memory, NULL (0) is returned.
' 
' Parameters: 
'     n: number of bytes
'
' Returns:
'	16 bits (pointer) unsigned integer. NULL is returned if not
'	enough memory to alloc the block
' ----------------------------------------------------------------
function FASTCALL allocate(byval n as uinteger) as uinteger
	' This is a FastCall function. This means:
	'     1.- The 16 bit 'n' parameter is received in hl
	'     2.- Can return at any point with "ret"
	'     3.- The result (16bit) must be returned in HL
	asm
	ld b, h
	ld c, l
	jp __MEM_ALLOC ; Since malloc is FASTCALL, we can return from there
	end asm
end function


' ----------------------------------------------------------------
' sub free
'
' Frees a block previously allocated with malloc, returning it
' to the heap.
' ----------------------------------------------------------------
sub FASTCALL deallocate(byval addr as integer)
	' This is a FastCall subroutine. This means:
	'     1.- The 16 bit 'n' parameter is received in hl
	'     2.- Can return at any point with "ret"
	asm
	jp __MEM_FREE
	end asm
end sub


' ----------------------------------------------------------------
' function realloc
'
' Reallocates the requested bytes in the heap (dynamic memory) and
' returns the address (16 bit, unsigned) of the new bloc. If
' no memory, NULL (0) is returned.
' 
' Parameters: 
'     n: number of bytes for the new size to reallocate
'
' Returns:
'	16 bits (pointer) unsigned integer. NULL is returned if not
'	enough memory to alloc the block
' ----------------------------------------------------------------
function FASTCALL reallocate(byval addr as uinteger, byval n as uinteger) as uinteger
	' This is a FastCall function. This means:
	'     1.- The 16 bit 'n' parameter is received in hl
	'     2.- The 2nd parameter is in the stack (16 bit) 
	'     3.- Can return at any point with "ret"
	'     4.- The result (16bit) must be returned in HL
	asm
	ex de, hl ; saves 'n' parameter in de
	pop hl    ; return address
	ex (sp), hl ; hl -> now contains the 2nd parameter (new length)
	ld b, h
	ld c, l
	ex de, hl ; recovers hl (current pointer)
	jp __REALLOC ; Since realloc is FASTCALL, we can return from there
	end asm
end function

#pragma pop(case_insensitive)

#require "alloc.asm"

#endif

