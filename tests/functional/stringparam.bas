' vim:ts=4:et:
' Test strings passed by VALUE parameter
' The string must be copied into the heap and
' its pointer pushed into the stack.

' The string must be freed upon SUB/Function exit
' to avoid memory leak


Sub testStr(a as String)
	print a
End Sub

testStr("Hello")

