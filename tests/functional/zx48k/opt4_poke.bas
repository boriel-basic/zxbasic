DIM dir as UInteger
DIM n as UByte
' Imprmimos una X
' Obtenemos la dirección del atributo
dir = 16384 + 6144
' Bucle infinito
DO
    ' Cambiamos el atributo con un poke (no borra la X)
    poke dir,n
    ' Incrementamos el atributo
    n=n+1
LOOP
