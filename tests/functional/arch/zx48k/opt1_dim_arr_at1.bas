CONST expr as Uinteger = 30000
DIM a(7, 5) as UInteger AT 30000
DIM b(2, 4) as UInteger

DIM c as UInteger

LET c = @a
LET c = @b
'LET c = @a(0, 0)
'LET c = @b(0, 0)

'DIM b as UInteger at expr
