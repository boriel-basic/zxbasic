REM circular dependency. Not compilable

DIM a as Ubyte at @b + 1
DIM b as Ubyte at @c + 1
DIM c as Ubyte at @a + 1

