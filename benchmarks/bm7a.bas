''' BM7 Benchmark by britlion.
''' Compiles on: ZX Basic, Hisoft, Sinclair BASIC
''' Expected running time: 2.1 segs (ZX BASIC)

7 REM :INT +a,k,v,i,m()
  DIM a, k, v, i as UInteger

8 REM : OPEN#
9 CLS 
10 POKE 23672,0: POKE 23673,0
90 POKE 23672,0
100 LET a=0: LET k=5: LET v=0
110 LET a=a+1
120 LET v=k/2*3+4-5
130 GO SUB 1000
140 DIM m(5) as UInteger
150 FOR i=1 TO 5
160 LET m(i)=a
170 NEXT i
200 IF a<1000 THEN GO TO 110: END IF
210 PRINT CAST(FIXED, PEEK(Uinteger, 23672))/50.0
999 STOP 
1000 RETURN 
1001 PRINT v, m(0)
