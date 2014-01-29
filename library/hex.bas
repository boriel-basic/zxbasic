' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_HEX__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_HEX__

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' ----------------------------------------------------------------
' function HEX
' 
' Parameters: 
'     num : 32 bit unsigned integer numbre
'
' Returns:
'	  4 chars str containing the HEX string representation
' ----------------------------------------------------------------
function FASTCALL hex(num as ULong) as String
	asm
	PROC
	LOCAL SUB_CHAR
	LOCAL SUB_CHAR2
	LOCAL END_CHAR
	LOCAL DIGIT

	push hl
	push de
	ld bc,10
	call __MEM_ALLOC
	ld a, h
	or l
	pop de
	pop bc
	ret z	; NO MEMORY

	push hl	; Saves String ptr
	ld (hl), 8
	inc hl
	ld (hl), 0
	inc hl  ; 8 chars string length

	call DIGIT
	ld d, e
	call DIGIT
	ld d, b
	call DIGIT
	ld d, c
	call DIGIT
	pop hl	; Recovers string ptr
	ret

DIGIT:
	ld a, d
	call SUB_CHAR
	ld a, d
	jr SUB_CHAR2

SUB_CHAR:	
	rrca
	rrca
	rrca
	rrca

SUB_CHAR2:
	and 0Fh
	add a, '0'	
	cp '9' + 1
	jr c, END_CHAR
	add a, 7

END_CHAR:
	ld (hl), a
	inc hl
	ret

	ENDP
	end asm
end function

	
REM 16 bit version
function hex16(n as UInteger) as String
	Dim a$ as String
	a$ = hex(n)
	return a$(4 TO 7)
end function


#pragma pop(case_insensitive)

' The following is required to allocate dynamic memory for strings
#require "alloc.asm"

#endif

