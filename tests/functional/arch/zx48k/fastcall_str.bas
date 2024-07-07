REM Should not free instring param when using FASTCALL
REM (it's up to the user)

testsub("mytest")

sub fastcall testsub(instring as string)

    asm
    pop hl
    nop
    end asm
end sub
