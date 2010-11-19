' Error: parameter mismatch (parameters mode mismatch)

DECLARE FUNCTION func0(a as Ubyte, b as Uinteger) as STRING

FUNCTION func0(a as Ubyte, ByRef b as Uinteger) as STRING
END FUNCTION


