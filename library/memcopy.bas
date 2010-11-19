' ----------------------------------------------------------------
' This file is released under the GPL v3 License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Use this file as a template to develop your own library file
' ----------------------------------------------------------------

#ifndef __LIBRARY_MEMCOPY__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_MEMCOPY__

#define memmove memcopy


' ----------------------------------------------------------------
' sub MEMCOPY(sourceaddr, destaddr, blocklength)
' 
' Parameters: 
'     souceaddr: memory address of source block to copy
'     destaddr:  memory address of destiny block to copy
'     length:    number of bytes to copy
'
' Copies block of memory from source to dest. Block may overlap
' ----------------------------------------------------------------
sub fastcall memcopy(source as uinteger, dest as uinteger, length as uinteger)
	asm
; Emulates both memmove and memcpy C routines
; Blocks will safely copies if they overlap

; HL => Start of source block
; DE => Start of destiny block
; BC => Block length

    exx
    pop hl ; ret addr
    exx 

    pop de ; dest
    pop bc ; length

    exx
    push hl ; stores ret addr back
    exx

   	jp __MEMCPY
	end asm
end sub

#require "memcopy.asm"

#endif

