
function MultiKeys(x as Ubyte) as Ubyte
    return x
end function


sub fastcall mainRoom()
	IF MultiKeys(0) then
		poke 0,1
	end if

	IF MultiKeys(1) then
		poke 1,0
	end if

	if MultiKeys(2) then
		poke 2,0
	end if

end sub

end

DIM dummy as Uinteger
dummy=@mainRoom
