' Declare a parameter of type string using $ sigil suffix

declare function test(s$)

function test$(s$)
    return s$ + "A"
end function

print test("H")

