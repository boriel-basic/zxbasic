' ----------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_MEMCOPY__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_MEMCOPY__

#pragma push(case_insensitive)
#pragma case_insensitive = True

' ----------------------------------------------------------------
' Sub MemMove(sourceaddr, destaddr, blocklength)
' 
' Parameters: 
'     souceaddr: memory address of source block to copy
'     destaddr:  memory address of destiny block to copy
'     length:    number of bytes to copy
'
' Copies block of memory safely from source to dest.
' Source and destiny blocks may overlap
' ----------------------------------------------------------------
sub fastcall MemMove(source as uinteger, dest as uinteger, length as uinteger)
	asm
; Emulates both memmove and memcpy C routines
; Blocks will safely copies if they overlap

; HL => Start of source block
; DE => Start of destiny block
; BC => Block length

    pop af ; ret addr
    pop de ; dest
    pop bc ; length
    push af ; stores ret addr back

   	jp __MEMCPY
	end asm
end sub


' ----------------------------------------------------------------
' Sub MemCopy(sourceaddr, destaddr, blocklength)
'
' Parameters:
'     souceaddr: memory address of source block to copy
'     destaddr:  memory address of destiny block to copy
'     length:    number of bytes to copy
'
' Copies block of memory from source to dest.
' Source and destiny blocks should not overlap.
' This sub is slighly faster than memmove
' ----------------------------------------------------------------
sub fastcall MemCopy(source as uinteger, dest as uinteger, length as uinteger)
	asm
; Emulates both memmove and memcpy C routines
; Blocks will safely copies if they DON'T overlap

; HL => Start of source block
; DE => Start of destiny block
; BC => Block length

    pop af  ; ret addr
    pop de  ; dest
    pop bc  ; length
    push af ; stores ret addr back
    ldir
	end asm
end sub


#require "memcopy.asm"

#pragma pop(case_insensitive)

#endif

