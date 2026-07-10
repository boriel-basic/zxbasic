' ----------------------------------------------------------------------
' joy.bas (zx81sd) — Configuracion del joystick programable del SD81
'
' El SD81 Booster mapea el joystick fisico a pulsaciones de teclado.
' El mapeo se configura con el comando 21 ($15) del MCU, que recibe 5
' codigos de tecla ZX81: arriba, abajo, izquierda, derecha y fuego.
'
' Uso:
'   #include <joy.bas>
'   dim st as ubyte
'   st = Joy("QAOPM")    ' arriba=Q abajo=A izq=O der=P fuego=M
'   st = Joy("7657 ")    ' cursores de Sinclair (fuego=espacio)
'
' La cadena debe tener exactamente 5 caracteres, en el orden
' ARRIBA, ABAJO, IZQUIERDA, DERECHA, FUEGO. Caracteres validos:
' letras (A-Z, indistinto mayus/minus), digitos (0-9) y espacio.
'
' Devuelve el byte de estado del MCU: 0 = OK, 14 = parametro invalido.
' Si la cadena es invalida (longitud o caracteres) devuelve 14 sin
' llegar a llamar al MCU.
' ----------------------------------------------------------------------

#pragma once

#include <mcu.bas>

#pragma push(explicit)
#pragma explicit = true

const _JOY_CMD as ubyte = $15   ' comando 21 del MCU: configurar joystick

' Convierte un caracter ASCII al codigo de tecla ZX81 que espera el MCU
' (0 = espacio, 28-37 = digitos, 38-63 = letras).
' Devuelve 255 si el caracter no corresponde a ninguna tecla valida.
function _JoyKeyCode(c as ubyte) as ubyte
    if c = code(" ") then
        return 0
    end if
    if c >= code("0") and c <= code("9") then
        return 28 + (c - code("0"))
    end if
    if c >= code("a") and c <= code("z") then
        c = c - 32
    end if
    if c >= code("A") and c <= code("Z") then
        return 38 + (c - code("A"))
    end if
    return 255
end function

' Configura el mapeo del joystick programable.
' keys: 5 caracteres en orden ARRIBA, ABAJO, IZQUIERDA, DERECHA, FUEGO.
' Devuelve el estado del MCU (0 = OK).
function Joy(keys as string) as ubyte
    dim i as ubyte
    dim kc as ubyte
    dim zxcodes as string

    if len(keys) <> 5 then
        return 14                    ' mismo codigo que usa el MCU
    end if

    ' valida y convierte ANTES de tocar el MCU, para no dejar el
    ' protocolo a medias si hay un caracter invalido
    zxcodes = ""
    for i = 0 to 4
        kc = _JoyKeyCode(code(keys(i)))
        if kc = 255 then
            return 14
        end if
        zxcodes = zxcodes + chr(kc)
    next i

    return McuCmdStr(_JOY_CMD, zxcodes)
end function

#pragma pop(explicit)
