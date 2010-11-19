
' Simple 8 bit multiplication benchmark

DIM a as Ubyte = 8
DIM t as Uinteger
DIM q as UByte

POKE Uinteger 23672, 0

FOR t = 0 to 65534
    q = a * 165
NEXT t


t = Peek(Uinteger, 23672)

print CAST(Fixed, t) / 50

END
PRINT q


