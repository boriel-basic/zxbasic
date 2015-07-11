
function ScanField(x as integer,y as integer,mask as ubyte) as ubyte
   if x>=0 and x<8 and y>=0 and y<8 then
      adr=@overlay+(y<<3)+x
      return peek adr band mask
   Else
      return 0
   end if
end function
sub SetField(x as uinteger,y as uinteger,fig as ubyte)
   dim adr as uinteger
   adr=@overlay+(y<<3)+x
   poke adr,(peek adr) bor fig
end sub

function ScanNear(x as ubyte,y as ubyte) as ubyte
'This scans next fields of x,y until figure for king or pawn
  dim result as ubyte
  if ScanField(x-1,y-1,7)=1 or ScanField(x+1,y-1,7)=1 then result=1:end if
   if ScanField(x-1,y-1,7)=6 or ScanField(x,y-1,7)=6 or ScanField(x+1,y-1,7)=6 or ScanField(x-1,y,7)=6 or ScanField(x+1,y,7)=6 or ScanField(x-1,y+1,7)=6 or ScanField(x,y+1,7)=6 or ScanField(x+1,y+1,7)=6 then result=result bor 32:end if
   return result
end Function

SetField(x,y,3)
ScanNear(x, y)


chessboard:

overlay:

