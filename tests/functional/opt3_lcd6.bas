
function ScanField(x as integer,y as integer,mask as ubyte) as ubyte
   if x>=0 and x<8 and y>=0 and y<8 then
      adr=@overlay+(y<<3)+x
      return peek adr band mask
   Else
      return 0
   end if
end function
chessboard:

overlay:

