DIM a as Ubyte

FUNCTION editStringFN(ByREF s AS Byte) as s
    s = s + 1
    RETURN s
END FUNCTION

a = editStringFN(a, 1, "i")

