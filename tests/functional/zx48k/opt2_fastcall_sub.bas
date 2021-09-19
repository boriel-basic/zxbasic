
function test(a as UByte) as Ubyte
   return a + 1
end function


sub c1()
   test(1) + test(2)
end sub


sub fastcall c2()
   test(1) + test(2)
end sub


c1()
c2()
