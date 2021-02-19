nop


push namespace MAIN

AA:
ld a, (AA)

pop namespace

ld a, (MAIN.AA)

