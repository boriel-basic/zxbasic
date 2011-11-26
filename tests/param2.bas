' Declare a parameter of type string using $ sigil suffix

declare function test(s$) as string

function test(s$)
    return s$ + "A"
end function

print test("H")

