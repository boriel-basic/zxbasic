
DIM a(5) as UByte => {0, 1, 2, 3, 4, 5}
DIM i as UInteger

i = 3
LET a(i) = 7
POKE 0, a(i)
