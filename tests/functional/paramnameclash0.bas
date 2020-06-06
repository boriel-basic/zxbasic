
DIM a(5) as UByte

REM parameter 'a' clashes with that of the array above
Sub test(a as UInteger)
   POKE a, 0
End Sub

test(1)

