dim a as ubyte
dim bPtr as uinteger

for bPtr = 32768 to 32768 + 25
a = peek(bPtr) bxor 255
poke bPtr, a
next bPtr

