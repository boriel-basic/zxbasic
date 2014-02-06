
sub test2(ByRef x$)
    print x$
end sub

sub test(ByVal x$)
    test2(x$)
end sub


test("ZXBASIC")
