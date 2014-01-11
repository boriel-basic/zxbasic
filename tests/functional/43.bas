
function test(byval a as uByte) as float
    DIM b(2) as Ubyte => {0AAh, 0BBh, 0CCh}
    return a + b(1)
end function


