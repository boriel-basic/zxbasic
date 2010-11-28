' vim:ts=4:et:
' Checks SP is not removed on -O3 peephole optimization

sub test(param as UInteger)
    dim a1, a2, a3, a4, a5
    a1 = param
    a2 = a1
    a3 = a2 + a2
    a4 = a3 + a2
    a5 = a3 + a2 + a1

end sub


test(10)

