DIM a as Ubyte = 4
DIM b(2, 3) as Ubyte => {{0A0h, 0A1h, 0A2h, 0A3h}, _
                         {0B0h, 0B1h, 0B2h, 0B3h}, _
                         {0C0h, 0C1h, 0C2h, 0C3h}}
LET b(1, 3) = a

