REM when compiling with --explicit this should
REM raise an error

#pragma explicit=true

DIM r(5, 5) As Ubyte
DIM q as Ubyte

for x = 1 to 5
  for y = 1 to 5
     q = r(y, x)
  next
next
