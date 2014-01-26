print peek(uinteger,@test)
print peek(@test)+256*peek(@test+1)
End
test:
asm
   defw 35600
end asm
