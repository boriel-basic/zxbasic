
buffer:

Sub F(pbuffer)
end Sub

Function S() as byte
	F(@buffer)
End Function

S()
