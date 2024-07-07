
function test(a as UByte) as Ubyte
   DIM x as Uinteger = 1
   print(a)
   return a + 1
end function


function c1() as Ubyte
   return test(1) + test(2)
end function


function fastcall c2() as UByte
   return test(1) + test(2)
end function


POKE 0, c1()
POKE 0, c2()
