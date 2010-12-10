' TEST for Bitwise OR 32 bits

DIM a as ULong
DIM b as UByte

b = a bOR 0
b = a bOR 1
b = a bOR 0FFFFh
b = 0 bOR a
b = 1 bOR a
b = 0FFFFh bOR a
b = a bOR a

