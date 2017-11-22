
function ScanNear(x as ubyte,y as ubyte) as ubyte
'This scans next fields of x,y until figure for king or pawn
  dim result as ubyte
  if x=1 or y=1 then result=1:end if
  return result
end Function

ScanNear(x, y)

