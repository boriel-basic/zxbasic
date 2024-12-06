dim a as UInteger
let a = peek(uinteger,@test)
let a = peek(@test)+256*peek(@test+1)
End
test:
asm
   defw 35600
end asm
