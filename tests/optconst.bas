'Optimization of constants test

POKE @label1 + 1, 0
POKE 2 + @label1, 0
POKE Uinteger 2 + @label2 * 5 - @label1, @label2 + @label1 * 3
POKE ULong 2 + @label2 * 5 - @label1, @label2 + @label1 * 3
POKE ULong 2 + 2, @label2 + @label1 * 3

DIM a as ULONG

a = @label1 + @label2

END
PRINT a

label1:
label2:


