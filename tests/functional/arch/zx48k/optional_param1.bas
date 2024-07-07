

REM declaring a mandatory parameter after
REM an optional one (x) is not allowed

sub test(x as Uinteger = 0, y)
end sub


test(1, 2)
