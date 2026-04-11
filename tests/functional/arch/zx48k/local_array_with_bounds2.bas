#pragma array_check=true

sub Sub1()
    dim i as uByte
    dim a(2) as uInteger

    i=2
    a(i-1)=7

    POKE 0,a(1)
end sub



Sub1
