REM Factorial recursive test

DIM result as ulong = 1

sub fact(x as ulong)
	if x < 2 then
	    return	
	end if

    result = result * x
	fact(x - 1)
end sub 

cls
for x = 1 To 10:
    result = 1
    fact(x)
	print "Fact ("; x; ") = "; result 
next x

