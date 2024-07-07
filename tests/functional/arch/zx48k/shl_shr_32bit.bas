
DIM a as UByte = 0
DIM c as ULong = 0x7FFF
DIM d as Long = -512
DIM result as UInteger

LET result = (c >> 0)
LET result = (c >> 1)
LET result = (c >> 2)
LET result = (c >> a)

LET result = (c << 0)
LET result = (c << 1)
LET result = (c << 2)
LET result = (c << a)

LET result = (d >> 0)
LET result = (d >> 1)
LET result = (d >> 2)
LET result = (d >> a)

LET result = (d << 0)
LET result = (d << 1)
LET result = (d << 2)
LET result = (d << a)
