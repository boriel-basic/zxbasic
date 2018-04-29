REM variables with AT should never be optimized
REM they don't take space and might have collateral (desired) effects
DIM UDGptr As Uinteger AT 23675
LET UDGptr = 65000

