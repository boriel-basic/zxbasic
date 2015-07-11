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
' function ATTR
' 
' Parameters: 
'     row: screen row
'     col: screen column
'
' Returns:
'     a byte value containing the screen attribute color value
' ----------------------------------------------------------------
function attr(byval row as ubyte, byval col as ubyte) as ubyte
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
' sub SETATTR
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


' ----------------------------------------------------------------
' function fastcall ATTRADDR
' 
' Parameters: 
'     row: screen row
'     col: screen column
'
' Action: Gets the attribute address of screen(row, column)
' ----------------------------------------------------------------
function fastcall attraddr(byval row as ubyte, byval col as ubyte) as uinteger
    asm   
                   ; a = row
    pop hl         ; ret address
    ex (sp), hl    ; Callee => H now has the col
    ld d, a        ; row
    ld e, h
    jp __ATTR_ADDR ; Return directly from there
    end asm
end function



#pragma pop(case_insensitive)

' The following is required, because it defines the SCREEN_ADDR constant.
#require "attr.asm"

' The following is required, because it defines the __IN_SCREEN subroutine.
#require "in_screen.asm"

#endif

