REM Factorial recursive test

function fact(x as ulong) as ulong
	if x < 2 then
		return 1
	end if

	return x * fact(x - 1)
end function

cls
for x = 1 To 10:
	print "Fact ("; x; ") = "; fact(x)
next x

