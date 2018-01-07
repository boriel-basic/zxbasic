asm
tablaColor  equ 2
tablaColorAlto equ tablaColor >> 8
tablaColorBajo equ tablaColor & 0xFF
tablaColorCheck equ (tablaColorAlto << 8) | tablaColorBajo
tabla1  equ tablaColor + 1
tabla2  equ tablaColor ^ 2
tabla3  equ tablaColor % 3
tabla4  equ tablaColor ~ 5

ld a, tablaColorAlto
ld b, tablaColorBajo
end asm

