
#define tablaSprites 40000

#define toloX (tablaSprites+11)
#define toloY (tablaSprites+12)
#define eggX (tablaSprites+32+11)
#define eggY (tablaSprites+32+12)


DIM subeEgg, sail as UByte



if sail=1 then
	if subeEgg=0 then
		if peek(toloX)<peek(eggX) then
			if abs(cast(byte,peek(eggY)-peek(toloY)))<16 then
				if abs(cast(byte,peek(toloX)-peek(eggX)))<20 then'24
					goto enddispara
				end if
			end if
		end if
	end if
end if

goto enddispara
END
enddispara:

