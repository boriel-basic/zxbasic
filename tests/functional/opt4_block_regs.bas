REM checks for register propagation
REM the cpu state of the preceding basic block(s)
REM can be propagated to the current one for deeper
REM optimizations

DIM x As Uinteger
#define spriteTimer (x + 25)

if peek(spriteTimer)>50 then
    poke spriteTimer,0
end if

