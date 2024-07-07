REM Test array substring assignation
REM Test assignation of a constant string

DIM a$(2)
a$(1) = "HELLO"

LET c$ = "A"

a$(1, 1) = c$ + "A": REM Alternative syntax: a$(1)(1) = c$ + "A"
