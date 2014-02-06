
sub test2(ByRef x as Uinteger)
    print x
end sub

sub test(ByVal x as Uinteger)
    test2(x)
end sub


test(1234)
