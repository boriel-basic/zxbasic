    GO TO 10

    sub FASTCALL test(flag AS UBYTE)
        asm
            cp 1
            jp m,45000
            jp 50000
        end asm
    end sub

    10 POKE 50000,201: POKE 45000,201
       test(1)

