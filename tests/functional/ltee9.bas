UDGS:
dim x as Uinteger

sub start()
   x = @UDGS
   x = (@UDGS/256)
   x = int(@UDGS/256)
   x = UDGS-((int(@UDGS/256))*256)
   c = @UDGS-((int(@UDGS/256))*256)
   x = (x/256)
   x = int(x/256)
   x = x-((int(x/256))*256)
   x=x-((int(x/256))*256)
end sub

