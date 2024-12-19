#line 1 "file2.bas"
#line 1 "file1.bas"
sub foo(a as ubyte, b as ubyte)
    print a, ", ", b
end sub

#line 2 "file2.bas"


foo(42, 43, 44)
