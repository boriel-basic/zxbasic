' TEST for Bitwise XOR 16 bits

DIM a as UByte
DIM b as UByte

b = a bXOR 0
b = a bXOR 1
b = a bXOR 0FFh
b = 0 bXOR a
b = 1 bXOR a
b = 0FFh bXOR a
b = a bXOR a

