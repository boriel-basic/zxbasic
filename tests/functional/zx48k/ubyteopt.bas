function CanDraw(x as ubyte, y as ubyte) as ubyte
  if y<0 or x<0 or y>20 or x>31 then return 0
  return 1
end function

CanDraw(1, 2)
