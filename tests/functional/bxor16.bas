' TEST for Bitwise XOR 16 bits

DIM a as UInteger
DIM b as UByte

b = a bXOR 0
b = a bXOR 1
b = a bXOR 0FFFFh
b = 0 bXOR a
b = 1 bXOR a
b = 0FFFFh bXOR a
b = a bXOR a

