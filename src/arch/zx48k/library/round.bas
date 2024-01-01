' ----------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyleft (k) 2024
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#pragma once
#pragma push(case_insensitive)
#pragma case_insensitive = True

' ----------------------------------------------------------------
' function ROUND
' 
' Parameters: 
'     n as Float: number to be rounded
'     y as Ubyte: number of decimals
'
' Returns:
'    A float rounded towards +/- infinity with the numbers of decimals
'    requested.
' ----------------------------------------------------------------
FUNCTION Round(n as Float, decimals as UByte = 0) AS Float
  DIM tmp as Float
  DIM d10 as Float = 10^decimals
  IF n >= 0 THEN
    LET tmp = INT(n * d10 + 0.5)
  ELSE
    LET tmp = INT(n * d10 - 0.5)
  END IF
  RETURN tmp / d10
END FUNCTION


#pragma pop(case_insensitive)
