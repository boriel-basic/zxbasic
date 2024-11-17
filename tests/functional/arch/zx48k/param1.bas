

function test(ByRef a as string)
    POKE 0, len(a$)
end function

a$="a"
test(a$)
