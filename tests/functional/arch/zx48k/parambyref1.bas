DIM dummy as Uinteger

sub test2(ByRef x as Uinteger)
    let dummy = x
end sub

sub test(ByVal x as Uinteger)
    test2(x)
end sub


test(1234)
