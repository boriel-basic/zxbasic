' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_ATTR__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_ATTR__

#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

' ----------------------------------------------------------------
' function fastcall ATTR
' 
' Parameters: 
'     row: screen row
'     col: screen column
'
' Returns:
'     a byte value containing the screen attribute color value
' ----------------------------------------------------------------
function attr(byval row as ubyte, byval col as ubyte) as ubyte

	' fastcall functions always receive the 1st parameter
	' in accumulator (if byte)
	asm

	PROC
	LOCAL __ATTR_END

    ld e, (ix+7)
    ld d, (ix+5)

    ; Checks for valid coords
    call __IN_SCREEN
    jr nc, __ATTR_END

    call __ATTR_ADDR
    ld a, (hl)	; byte values are returned in accumulator

__ATTR_END:
	ENDP 

	end asm

end function



' ----------------------------------------------------------------
' sub fastcall SETATTR
' 
' Parameters: 
'     row: screen row
'     col: screen column
'	  color: 8bit color attribute
'
' Action: Sets the attribute of screen(row, column) to the given
'		color attribute value.
' ----------------------------------------------------------------
sub setattr(byval row as ubyte, byval col as ubyte, byval value as ubyte)
	' fastcall functions always receive the 1st parameter
	' in accumulator (if byte)
	asm

	PROC
	LOCAL __ATTR_END

    ld e, (ix+7)
    ld d, (ix+5)

    ; Checks for valid coords
    call __IN_SCREEN
    jr nc, __ATTR_END

    call __ATTR_ADDR
	ld a, (ix+9)
    ld (hl), a	; "POKE" attr address, color value)

__ATTR_END:
	ENDP 

	end asm

end sub

#pragma pop(case_insensitive)

' The following is required, because it defines the SCREEN_ADDR constant.
#require "attr.asm"

' The following is required, because it defines the __IN_SCREEN subroutine.
#require "in_screen.asm"

#endif

