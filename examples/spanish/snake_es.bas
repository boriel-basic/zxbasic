1  REM ********************************************************************
2  REM ZXSnake by Federico J. Alvarez Valero (05-02-2003)
10 REM This program is free software; you can redistribute it and/or modify
11 REM it under the terms of the GNU General Public License as published by
12 REM the Free Software Foundation; either version 2 of the License, or
13 REM (at your option) any later version.
14 REM This program is distributed in the hope that it will be useful,
15 REM but WITHOUT ANY WARRANTY; without even the implied warranty of
16 REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
17 REM GNU General Public License for more details.
18 REM You should have received a copy of the GNU General Public License
19 REM along with this program; if not, write to the Free Software
20 REM Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
30 REM                     SPANISH VERSION
40 REM ********************************************************************

50   BORDER 7 : PAPER 7 : INK 0 : CLS
51   PRINT AT 3,13 ; PAPER 1 ; INK 7 ; "ZXSnake"
52   PRINT AT 5,9 ; PAPER 7 ; INK 0 ; "Q - ARRIBA"
53   PRINT AT 6,9 ; PAPER 7 ; INK 0 ; "A - ABAJO"
54   PRINT AT 7,9 ; PAPER 7 ; INK 0 ; "O - IZQUIERDA"
55   PRINT AT 8,9 ; PAPER 7 ; INK 0 ; "P - DERECHA"
56   PRINT AT 10,3 ; PAPER 7 ; INK 0 ; "Recoge la mayor cantidad de"
57   PRINT AT 11,3 ; PAPER 7 ; INK 0 ; "frutas posible y crece"
58   PRINT AT 12,3 ; PAPER 7 ; INK 0 ; "sin chocarte..."
59   PRINT AT 15,3 ; PAPER 7 ; INK 0 ; "Pulsa una tecla para jugar"
60   LET j$ = INKEY$
61   IF j$ = "" THEN GOTO 60: END IF

70   REM UDG
71   DIM udg(1, 7) AS uByte => { {60, 66, 129, 129, 129, 129, 66, 60}, _
								 {24, 60, 60, 60, 126, 251, 247, 126}}
73	 POKE UINTEGER 23675, @udg(0, 0): REM Sets UDG variable to first element
74   LET S$ = CHR$(144): LET F$ = CHR$(145)

75   REM Declaracion de variables
76   DIM p(23,34) AS UBYTE: REM Pantalla
77   DIM x(23,34) AS UBYTE: REM Orientacionesx
78   DIM y(23,34) AS UBYTE: REM Orientacionesy

79   DIM c, f AS UBYTE 
80   DIM cabezax, cabezay AS UBYTE : REM coordenadas de las cabeza
81   DIM colax, colay AS UBYTE : REM coordenadas de las cola
90   DIM puntos, comido as ULONG
95   DIM maxx, maxy, minx, miny as UByte

100  REM Definicion de variables
110  LET cabezax = 11 : REM coordenada x de la cabeza
120  LET cabezay = 5 : REM coordenada y de la cabeza
130  LET colax = 5 : REM coordenada x de la cola
140  LET colay = 5 : REM coordenada y de la cola
150  LET orientacionx = 1
160  LET orientaciony = 0

165  REM Limpia arrays p, x e y
170  FOR c = 1 to 23: FOR f = 1 to 34
180  LET p(c, f) = 0: LET x(c, f) = 0: LET y(c, f) = 0
190  NEXT f: NEXT c

200  LET puntos = 0
210  LET comido = 0
220  LET maxx = 33
230  LET maxy = 22
240  LET minx = 0
250  LET miny = 0

1000 REM Inicializacion de la pantalla
1010 BORDER 1
1015 CLS
1020 PRINT AT 21,0 ; PAPER 1 ; INK 7 ; " PUNTOS :                       "
1030 FOR c = minx TO maxx
1040 LET p(miny+1,c+1) = 4
1050 LET p(maxy+1,c+1) = 4
1060 NEXT c
1070 FOR f = miny TO maxy
1080 LET p(f+1,minx+1) = 4
1090 LET p(f+1,maxx+1) = 4
1100 NEXT f  

1500 GOSUB 8000 : REM Generar la primera fruta

2000 REM Pintamos la serpiente (posicion inicial)
2001 PAPER 7 : INK 0
2005 REM Pintamos el cuerpo
2010 FOR c = colax TO cabezax-1
2020 PRINT AT colay,c ; INK 0 ; "O"
2025 LET p(colay+2,c+2) = 3
2026 LET x(colay+2,c+2) = 1
2027 LET y(colay+2,c+2) = 0
2030 NEXT c
2040 REM Pintamos la cabeza
2050 PRINT AT cabezay,cabezax ; INK 0 ; S$;
2055 LET p(cabezay+2,cabezax+2) = 2
2056 LET x(cabezay+2,cabezax+2) = 1
2057 LET y(cabezay+2,cabezax+2) = 0

3000 REM Movemos la serpiente
3005 INK 0
3010 REM Cambiamos la orientacion
3015 LET x(cabezay+2,cabezax+2) = orientacionx
3020 LET y(cabezay+2,cabezax+2) = orientaciony
3025 REM Borramos la antigua cabeza
3030 PRINT AT cabezay,cabezax ; "O"
3035 LET p(cabezay+2,cabezax+2) = 3
3040 LET cabezax = cabezax + orientacionx
3045 LET cabezay = cabezay + orientaciony
3050 IF p(cabezay+2,cabezax+2) > 1 THEN GOTO 9900: END IF
3051 IF p(cabezay+2,cabezax+2) = 1 THEN
     LET puntos = puntos + 10 : PRINT AT 21,10 ; _
     PAPER 1 ; INK 7 ; puntos : LET comido = 1 : GOSUB 8000: END IF
3055 REM Pintamos la nueva cabeza
3060 PRINT AT cabezay,cabezax ; S$;
3065 LET p(cabezay+2,cabezax+2) = 2
3070 IF comido = 0 THEN GOSUB 8100: END IF
3080 LET comido = 0

3200 REM Leemos el teclado
3210 LET a$ = INKEY$
3220 IF orientacionx < 1 AND (a$ = "O" OR a$ = "o") THEN
     LET orientacionx = -1 : LET orientaciony = 0: END IF
3230 IF orientacionx > -1 AND (a$ = "P" OR a$ = "p") THEN
     LET orientacionx = 1 : LET orientaciony = 0: END IF
3240 IF orientaciony < 1 AND (a$ = "Q" OR a$ = "q") THEN
     LET orientacionx = 0 : LET orientaciony = -1: END IF
3250 IF orientaciony > -1 AND (a$ = "A" OR a$ = "a") THEN
     LET orientacionx = 0 : LET orientaciony = 1: END IF

3500 REM Pausa / Delay
3505 BEEP 0.005, 0
3510 FOR i = 1 TO 500:
	 NEXT i

7998 GOTO 3000

8000 REM Generacion de frutas
8010 LET frutax = INT(RND*30)+1
8020 LET frutay = INT(RND*20)+1
8030 IF p(frutay+2,frutax+2) = 0 THEN GOTO 8050: END IF
8040 GOTO 8010
8050 PRINT AT frutay,frutax ; INK 2 ; F$;
8060 LET p(frutay+2,frutax+2) = 1
8070 RETURN

8100 REM Borramos la cola
8110 PRINT AT colay,colax ; " "
8120 LET nuevacolax = colax + x(colay+2,colax+2)
8130 LET nuevacolay = colay + y(colay+2,colax+2)
8140 LET p(colay+2,colax+2) = 0
8150 LET x(colay+2,colax+2) = 0
8160 LET y(colay+2,colax+2) = 0
8170 LET colax = nuevacolax
8180 LET colay = nuevacolay
8190 RETURN

9900 REM Fin de la partida
9910 PRINT AT 10,12 ; INK 2 ; "SE ACABO..."
9920 PRINT AT 11,10 ; INK 2 ; "PUNTUACION : " ; puntos
9930 PRINT AT 13,10 ; INK 0 ; "Pulsa una tecla"
9931 REM Pausa obligada para que se vean los letreros
9932 FOR i = 0 TO 100

9933 NEXT i
9940 LET j$ = INKEY$
9950 IF j$ <> "" THEN GOTO 100: END IF
9960 GOTO 9940



