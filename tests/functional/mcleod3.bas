Sub DisplayDirectoryTree (ByVal path$ as string, ByVal graph$ as string)
  Dim entry$ as string
  DisplayDirectoryTree (entry$, graph$+GenerateSpaces(LEN entry$ -1)+"|")
End Sub

Function GenerateSpaces (ByVal n as Byte) as string
End Function
