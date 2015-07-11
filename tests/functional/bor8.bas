' TEST for Bitwise OR 16 bits

DIM a as UByte
DIM b as UByte

b = a bOR 0
b = a bOR 1
b = a bOR 0FFh
b = 0 bOR a
b = 1 bOR a
b = 0FFh bOR a
b = a bOR a

