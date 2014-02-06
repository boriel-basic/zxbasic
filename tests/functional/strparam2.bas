
sub test2(ByRef x$)
    print x$
end sub

sub test(ByRef x$)
    test2(x$)
end sub

a$="ZXBASIC"
test(a$)
