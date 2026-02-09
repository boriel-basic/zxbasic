dim   var_neg   as fixed = -1.5
const const_neg as fixed = -1.5
dim   var as Fixed = 1.5
const const_ as fixed = 1.5
dim   var_neg_fl as Float = -1.5
const const_neg_fl as Float = -1.5

DIM r_int as Integer
DIM r_long as Long
DIM r_ulong as ULong

LET r_int = cast(integer, var_neg)
LET r_int = cast(integer, const_neg)
LET r_long = cast(long, var_neg)
LET r_ulong = cast(ulong, var_neg)

LET r_int = cast(integer, var)
LET r_int = cast(integer, const_)
LET r_long = cast(long, var)
LET r_ulong = cast(ulong, var)

LET r_int = cast(integer, var_neg_fl)
LET r_int = cast(integer, const_neg_fl)
LET r_long = cast(long, var_neg_fl)
LET r_ulong = cast(ulong, var_neg_fl)
