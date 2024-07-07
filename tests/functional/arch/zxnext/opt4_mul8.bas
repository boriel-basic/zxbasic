dim x as uinteger
dim y as ubyte

y = 1

printTest(x*16,y*16)

sub printTest(xpos as uinteger, ypos as ubyte)
  poke 0, ypos
end sub
