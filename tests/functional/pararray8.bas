
Function max(a() as Ubyte) as Ubyte
   DIM max as UByte
   max = a(0)
   for i = 1 to 5
      if max < a(i) then max = a(i)
   next
   return max
End Function

DIM a(5) as Ubyte = {4, 3, 1, 5, 7, 8}
maximum = max(a)

