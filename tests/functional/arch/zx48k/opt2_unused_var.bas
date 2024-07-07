' BugTest
Check()
pause 0


function TestPrint(y as ubyte, x as ubyte)
  poke 0, x
  poke 0, y
end function


SUB Check()
  dim y as ubyte
  y=TestPrint(5,10) * 5 + (4 + TestPrint(6, 11))
end sub
