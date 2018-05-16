DIM toloX, toloY as UInteger
DIM doorX, doorY as UByte

if peek(toloX)<3 or peek(toloX)>107 or peek(toloY)<2 or peek(toloY)>86 or (peek(toloX)=doorX and peek(toloY)=doorY) THEN 
'if (peek(toloX)=doorX and peek(toloY)=doorY) THEN 
     poke toloX, 0
end if 

