' ----------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#ifndef __LIBRARY_SCRBUFFER__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_SCRBUFFER__

#pragma push(case_insensitive)
#pragma case_insensitive = True

REM Put your code here.

' ----------------------------------------------------------------
' function GetScreenBufferAddr
'
' Returns:
'     The address of the Screen Buffer
' ----------------------------------------------------------------
Function Fastcall GetScreenBufferAddr As UInteger
Asm
  ld hl, (.core.SCREEN_ADDR)
End Asm
End Function


' ----------------------------------------------------------------
' function SetScreenBufferAddr
'
' Sets the address of the screen buffer and returns it
'
' Parameters:
'  - Address: Uinteger value with the new address
'
' Returns:
'     The address of the screen buffer
' ----------------------------------------------------------------
Function Fastcall SetScreenBufferAddr(addr As UInteger) As UInteger
Asm
  ld (.core.SCREEN_ADDR), hl
End Asm
End Function


' ----------------------------------------------------------------
' function GetAttrBufferAddr
'
' Returns:
'     The address of the attribute buffer
' ----------------------------------------------------------------
Function Fastcall GetAttrBufferAddr As UInteger
Asm
  ld hl, (.core.SCREEN_ATTR_ADDR)
End Asm
End Function


' ----------------------------------------------------------------
' function SetScreenBufferAddr
'
' Sets the address of the attribute buffer and returns it
'
' Parameters:
'  - Address: UInteger value with the new address
'
' Returns:
'     The address of the attribute buffer
' ----------------------------------------------------------------
Function Fastcall SetAttrBufferAddr(addr As UInteger) As UInteger
Asm
  ld (.core.SCREEN_ATTR_ADDR), hl
End Asm
End Function


#require "sysvars.asm"
#pragma pop(case_insensitive)

#endif

