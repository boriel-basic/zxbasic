#pragma once

Function fastcall hMirror(number as uByte) as uByte
    Asm
    ;17 bytes and 66 clock cycles
        ld b,a       ;b=ABCDEFGH
        rrca         ;a=HABCDEFG
        rrca         ;a=GHABCDEF
        xor b
        and %10101010
        xor b        ;a=GBADCFEH
        ld b,a       ;b=GBADCFEH
        rrca         ;a=HGBADCFE
        rrca         ;a=EHGBADCF
        rrca         ;a=FEHGBADC
        rrca         ;a=CFEHGBAD
        xor b
        and %01100110
        xor b        ;a=GFEDCBAH
        rrca         ;a=HGFEDCBA
    End Asm
End Function
