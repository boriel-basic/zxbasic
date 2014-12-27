    asm
        call    $fc12
        di
        ld      a, $fe
        ld      i, a
        im      2
        ei
    end asm


