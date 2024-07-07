
sub test(x as Uinteger, y as Ubyte = 4)
    POKE 0, x + y
end sub

test x:=1
