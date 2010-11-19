' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' ZX SCREEN$ function contributed by mcleod_idafix <http://foro.speccy.org>
' ----------------------------------------------------------------

#ifndef __LIBRARY_SCREEN__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SCREEN__

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' ----------------------------------------------------------------
' function fastcall SCREEN
' 
' Parameters: 
'     row: screen row
'     col: screen column
'
' Returns:
'     a string containing the screen char value
' ----------------------------------------------------------------
function screen(byval row as ubyte, byval col as ubyte) as string

	' fastcall functions always receive the 1st parameter
	' in accumulator (if byte)
	Dim result as String 

	asm

	PROC
	LOCAL __SCREEN_END

	LOCAL __S_SCRNS_BC
	LOCAL STK_END
	LOCAL RECLAIM2

__S_SCRNS_BC EQU 2538h
STK_END EQU 5C65h
RECLAIM2 EQU 19E8h

	ld bc, 4
	call __MEM_ALLOC
	push hl			; Saves memory pointer

	ld a, h
	or l
	jr z, __SCREEN_END	; Return NULL if no memory

	ld hl, (STK_END)
	push hl

	ld b, (ix+7)	; row
	ld c, (ix+5)	; column

	call __S_SCRNS_BC
	call __FPSTACK_POP

	pop hl
	ld (STK_END), hl

	pop hl
	push hl

	ld (hl), c
	inc hl
	ld (hl), b
	inc hl
	ld a, (de)
	ld (hl), a

	ex de, hl
	call RECLAIM2

__SCREEN_END:
	pop hl
	ld (ix-2), l
	ld (ix-1), h

	ENDP 

	end asm

	return result

end function

#pragma pop(case_insensitive)


' The following is required to allocate dynamic memory for strings
#require "alloc.asm"

' The following is required to manipulate the FP-CALC stack
#require "stackf.asm"

#endif

