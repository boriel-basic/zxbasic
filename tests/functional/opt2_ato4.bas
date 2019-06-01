dim toloX, toloY as Uinteger
dim doorX, doorY as UByte
if peek(toloX)<3 or peek(toloX)>107 or peek(toloY)<2 or peek(toloY)>86 or (peek(toloX)=doorX and peek(toloY)=doorY) or toloX > toloY THEN 
doorX = 0
end if
