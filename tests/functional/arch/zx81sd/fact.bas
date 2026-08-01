REM Factorial recursive test
DIM y as ulong

function fact(x as ulong) as ulong
	if x < 2 then
		return 1
	end if

	return x * fact(x - 1)
end function

for x = 1 To 10:
    let y = x: rem dummy
next x
