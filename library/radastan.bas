' ----------------------------------------------------------------
' This file is released under the GPL v3 License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
'
' Radastan mode library for ZX UNO and compatible machines
' ----------------------------------------------------------------

#ifndef __LIBRARY_RADASTAN__

REM Avoid recursive / multiple inclusion

#define __LIBRARY_RADASTAN__

' ----------------------------------------------------------------
' function NAME
'
' Parameters:
'     x <explanation>
'     y <explanation>
'
' Returns:
'     <explanation> (When nothing to return, use SUB instead)
' ----------------------------------------------------------------
sub RadastanMode(enable as Ubyte)
    OUT 64571, 64
    OUT 64827, 3 * enable
end sub


' ----------------------------------------------------------------
' function RadastanPlot
'
' Parameters:
'     x: coord x (horizontal) of pixel to plot
'     y: coord y (vertical) of pixel to plot
'     color: color palette (0..15)
' ----------------------------------------------------------------
sub fastcall RadastanPlot(x as ubyte, y as ubyte, color as ubyte)
    asm
    pop hl       ; ret addr
    pop de       ; D = y
    ld e, a      ; E = x
    ex (sp), hl  ; callee, h = color
    ld l, h      ; l = color
    xor a
    rr e
    adc a, a
    xor 1
    ld h, a
    ld a, d      ;' recuperamos el valor vertical
    rrca
    rrca         ;' rotamos para dejar su valor en multiplos de 64 (linea, de dos en dos pixels)
    and 192      ;' borramos el resto de bits por si las moscas
    or e         ;' sumamos el valor horizontal
    ld e, a      ;' e preparado
    ld a, d      ;' cargamos el valor vertical
    rrca
    rrca         ;' rotamos para quedarnos con los bits altos
    and 63       ;' borramos el resto de bits
    or 64        ;' nos posicionamos a partir de 16384 (16384=64+0 en dos bytes)
    ld d, a      ;' d preparado, ya tenemos la posicion en pantalla
    ld a,(de)
    rr h
    jr c, rplotnext2
    and 240
    or l
    jr rplotfin

rplotnext2:
    and 15
    rl l
    rl l
    rl l
    rl l
    or l

rplotfin:
    ld (de), a
    end asm
end sub


sub RadastanPalette(color, rgb as UByte) ' color=0-15, rgb = binary GGGRRRBB
   OUT 48955, 64: OUT 65339, 1
   OUT 48955, color: OUT 65339, rgb
end sub


sub fastcall RadastanCls(color as ubyte)
   asm
   and 0xF
   ld b, a
   rla
   rla
   rla
   rla
   or b
   ld hl, 16384
   ld de, 16385
   ld bc, 6143
   ld (hl), a
   ldir
   end asm
end Sub

#endif