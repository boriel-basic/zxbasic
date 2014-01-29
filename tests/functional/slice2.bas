    CLS
     
    doubleSizePrint(10,0,"Hello World")


    STOP

     
    SUB doubleSizePrint(y AS UBYTE, x AS UBYTE, thingToPrint$ AS STRING)
    'Uses doubleSizePrintChar subroutine to print a string.
    'By Britlion, 2012
     
       DIM n AS UBYTE
       FOR n=0 TO LEN thingToPrint - 1
           LET a$ = thingToPrint$(n)
          x=x+2
       NEXT n
    END SUB

