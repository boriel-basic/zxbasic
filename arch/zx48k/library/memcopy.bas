' ----------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyleft (k) 2008-2018
' Contributed by:
'   - Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'   - Miguel Angel Diaz-Jodar (a.k.a. McLeod_Ideafix) <http://zxuno.speccy.org/>
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

    exx
    pop hl  ; uses HL' to preserve HL
    exx
    pop de  ; dest
    pop bc  ; length
    exx
    push hl ; stores ret addr back
    exx
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
' This sub is slightly faster than memmove
' ----------------------------------------------------------------
sub fastcall MemCopy(source as uinteger, dest as uinteger, length as uinteger)
	asm
; Emulates both memmove and memcpy C routines
; Blocks will safely copies if they DON'T overlap

; HL => Start of source block
; DE => Start of destiny block
; BC => Block length

    exx
    pop hl  ; uses HL' to preserve HL
    exx
    pop de  ; dest
    pop bc  ; length
    exx
    push hl ; stores ret addr back
    exx
    ldir
	end asm
end sub


' ----------------------------------------------------------------
' Sub MemSet(destaddr, value, blocklength)
'
' Parameters:
'     destaddr:  memory address of destiny block to fill
'     value:     value to fill with
'     length:    number of bytes to fill
'
' ----------------------------------------------------------------
sub fastcall MemSet(dest as uinteger, value as ubyte, length as uinteger)
    asm

; HL => Start of destination block
; DE => Value (D)
; BC => Block length

    pop de  ; ret addr
    pop af  ; value
    pop bc  ; length
    push de ; stores ret addr back
    ld (hl),a
    dec bc
    ld a, b
    or c
    ret z
    ld d,h
    ld e,l
    inc de
    ldir
    end asm
end sub


#require "memcopy.asm"

#pragma pop(case_insensitive)

#endif

