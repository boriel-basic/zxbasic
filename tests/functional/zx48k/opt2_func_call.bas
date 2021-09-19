REM Should ignore c2 and c3, never used
function test(a as UByte) as Ubyte
   DIM x as Uinteger = 1
   print(a)
   return a + 1
end function


function c1() as Ubyte
   return test(1)
end function


function c3() as Ubyte
	return 1
end function


function c2() as UByte
   return test(1) + test(2) + c3()
end function


POKE 0, c1()
