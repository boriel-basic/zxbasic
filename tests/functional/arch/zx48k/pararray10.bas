REM Test passing a global array to another function
REM (parameter as parameter!)

DIM a(3) as UInteger => {10, 11, 12, 13}

Function func1(a() as UInteger, i as UInteger) as UInteger
    return a(i)
End Function

Function func2(a() as UInteger, i as UInteger) as UInteger
    return func1(a, i)
End Function

DIM i as UInteger
For i = 0 to 3
   LET c = func2(a, i)
Next
