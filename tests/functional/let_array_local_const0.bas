
rightCellValue = 1
downCellValue = 2
leftCellValue = 3
upCellValue = 4

DIM i as UInteger = 1

sub test
  'Dim a as UInteger = 0
  Dim dirs(4) as byte

dirs(2) = downCellValue
dirs(3) = leftCellValue

for i = 1 to 4: print dirs(i); " ";: next i
'dirs(i) = downCellValue
poke 0, dirs(0)
end sub

test
