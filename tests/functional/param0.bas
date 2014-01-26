' Declare a parameter of type string using $ sigil suffix

function test$(s$)
    return s$ + "A"
end function

print test("H")

