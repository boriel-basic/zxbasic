' vim:ts=4:et:
' Test strings returned from a function
' The string must be copied into the heap and
' its pointer returned in HL


Function testStr() as String
	Return "Hello"
End Function

Print testStr

