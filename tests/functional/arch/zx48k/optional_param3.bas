
sub test(x as Uinteger, y as Ubyte = "A")
    POKE 0, x + y
end sub

test(1)
