Sub Fastcall tdPutChar (c as uByte)
   Asm
      rst 16
   End Asm
End Sub

Sub tdPrint (cad As String)
   Dim i As uByte
   For i = 1 To Len (cad)
      tdPutChar (cad (i))
   Next i
End Sub

