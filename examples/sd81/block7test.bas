' BLOCK7TEST -- verifica si el mapeador ($E7) mapea de verdad la
' pagina 20 al bloque 7 ($E000-$FFFF), sin nada de MSFS por medio.
' Escribe un patron dependiente de direccion, cambia a otra pagina y
' vuelve, y comprueba que el contenido sigue ahi (paginas distintas =
' contenido independiente) y que el patron se lee correctamente.

#include <mcu.bas>

DIM addr AS UINTEGER
DIM v, expected AS UBYTE
DIM errors AS UINTEGER

CLS
PRINT "BLOCK7TEST"
PRINT

' Paso 1: mapear pagina 20 y rellenar con patron
Map(7, 20)
PRINT "Escribiendo pagina 20..."
FOR addr = $E000 TO $E0FF
    v = addr BAND 255
    POKE addr, v
NEXT addr

' Paso 2: cambiar a pagina 63 (la "libre") y rellenar con OTRO patron
Map(7, 63)
PRINT "Escribiendo pagina 63..."
FOR addr = $E000 TO $E0FF
    v = 255 - (addr BAND 255)
    POKE addr, v
NEXT addr

' Paso 3: releer pagina 63 (deberia tener el segundo patron)
errors = 0
FOR addr = $E000 TO $E0FF
    expected = 255 - (addr BAND 255)
    v = PEEK(addr)
    IF v <> expected THEN
        errors = errors + 1
        IF errors <= 3 THEN PRINT "pagina 63 mal en "; addr; ": "; v; "<>"; expected
    END IF
NEXT addr
PRINT "Pagina 63 tras releer: ";
IF errors = 0 THEN PRINT "OK" ELSE PRINT errors; " errores"

' Paso 4: volver a pagina 20 y comprobar que SIGUE el primer patron
' (si esto falla con "0", el bloque 7 no esta guardando datos por
' pagina de verdad -- todas las paginas comparten la misma RAM)
Map(7, 20)
errors = 0
FOR addr = $E000 TO $E0FF
    expected = addr BAND 255
    v = PEEK(addr)
    IF v <> expected THEN
        errors = errors + 1
        IF errors <= 3 THEN PRINT "pagina 20 mal en "; addr; ": "; v; "<>"; expected
    END IF
NEXT addr
PRINT "Pagina 20 tras volver: ";
IF errors = 0 THEN PRINT "OK" ELSE PRINT errors; " errores"

PRINT
PRINT "FIN"
