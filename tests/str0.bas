function test(s$ as string) as string
    print s$
    return s$ + "1"
end function

a=1
test(str$(a + 1))


