' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2025
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
' ----------------------------------------------------------------

#pragma once
#pragma push(case_insensitive)
#pragma case_insensitive = TRUE

function fastcall randInt() as ULong ' Returns a random ULong
  asm
    push namespace core
    call RAND
    pop namespace
  end asm
end function


Function fastcall randFixed() as Fixed ' Returns a random Fixed
  Asm
    push namespace core
    call RAND
    pop namespace
  End Asm
End Function


Function fastcall randomLimit(limit as uByte) as uByte
  Asm
    push namespace core
    PROC
    and a
    ret z ; Input zero, output zero.
    ld b, a ; Save A
    ld c,255
  1:
    rla
    jr c, 2f
    rr c
    jp 1b ; loop back until we find a bit.
  2:
    call RAND
    and c
    cp b
    ret z
    jr nc, 2b
    ENDP
    pop namespace
  End Asm
End Function

#pragma pop(case_insensitive)
#require "random.asm"
