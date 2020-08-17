REM circular dependency. Not compilable

DIM a at @b + 1
DIM b at @c + 1
DIM c at @a + 1

