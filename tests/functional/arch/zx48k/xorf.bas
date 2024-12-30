' TEST for Boolean XOR Float

DIM a as Float
DIM b as UByte

b = a XOR 0
b = a XOR 1
b = 0 XOR a
b = 1 XOR a
b = a XOR a
b = (a = a) XOR (a = a)

