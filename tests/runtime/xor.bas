DIM a as uByte = 5
DIM b as UByte = 0

if a xor b then PRINT "OK"
else PRINT "FAIL"
END IF

if a xor a then PRINT "FAIL"
ELSE PRINT "OK"
END IF

DIM a0 as Uinteger = 5
DIM b0 as UInteger = 0

if a0 xor b0 then PRINT "OK"
else PRINT "FAIL"
END IF

if a0 xor a0 then PRINT "FAIL"
ELSE PRINT "OK"
END IF

DIM a1 as ULONG = 5
DIM b1 as ULONG = 0

if a1 xor b1 then PRINT "OK"
else PRINT "FAIL"
END IF

if a1 xor a1 then PRINT "FAIL"
ELSE PRINT "OK"
END IF

DIM a2 as Fixed = 5
DIM b2 as Fixed = 0

if a2 xor b2 then PRINT "OK"
else PRINT "FAIL"
END IF

if a2 xor a2 then PRINT "FAIL"
ELSE PRINT "OK"
END IF

DIM a3 as Float = 5
DIM b3 as Float = 0

if a3 xor b3 then PRINT "OK"
else PRINT "FAIL"
END IF

if a3 xor a3 then PRINT "FAIL"
ELSE PRINT "OK"
END IF
