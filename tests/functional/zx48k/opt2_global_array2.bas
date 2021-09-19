DIM myArray(1 to 6) as ubyte
DIM myArray2(1 to 6) as Ubyte


SUB Init()
    DIM i as ubyte
    myArray(i) = 2 * myArray2(i)
END SUB

Init()
