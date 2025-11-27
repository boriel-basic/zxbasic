# TO

**TO** is a keyword used to specify a sequence of numbers to be used in a statement.

a TO b (STEP c) will give the statement a sequence of numbers starting at a and ending at [the closest number less than or equal to] b, 
with each number after a being the previous number plus 1, or c if the STEP keyword is used (only supported by FOR).
In the case of a TO b with a and b integers, the sequence will include both a and b.
A, B and C can be expressions, can be floating point numbers [FOR i = 0 TO PI / 2 STEP q - circle.bas.md]
Statements that can be used with TO are FOR, DIM [DIM b(0 TO 10) - dim.md, DIM a(3 TO 5, 1 TO 8) - lbound.md, only dimensions, indexes will only be valid within the declared range], [variable value assignments? NO, not even arrays], NOT array, string indexing [s$(TO N - 1) - left.md, s$(len(s$) - N - 1 TO) - right.md]
GO TO, despite having TO, is a different statement and these rules do not apply to it
