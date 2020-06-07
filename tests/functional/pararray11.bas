REM Test passing as parameter a local array to another function
REM (parameter as parameter!)

Function func1(a() as UInteger, i as UInteger) as UInteger
    return a(i)
End Function

Function func2(a() as UInteger, i as UInteger) as UInteger
    return func1(a, i)
End Function

Function func3()
    DIM a(3) as UInteger => {10, 11, 12, 13}
    DIM i as UInteger

    For i = 0 to 3
        LET c = func2(a, i)
    Next
End Function

func3

