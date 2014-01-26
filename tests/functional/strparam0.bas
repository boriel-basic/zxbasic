' Test nasty string param calls

function test2(s$)
    print s$
end function

function test1(s$)
    test2(s$)
end function

test1("Hello world")

