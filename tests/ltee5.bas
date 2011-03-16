dim testglobal as string

testglobal = "global"
setlocal()

sub setlocal
   dim testlocal as string
   testlocal = "local"
   testglobal = testlocal
end sub


