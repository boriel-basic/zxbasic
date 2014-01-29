REM IF then syntax

 5 DIM a AS BYTE

10 IF a < 1 THEN
   a = a + 1
20 ELSEIF a > 0 THEN
   a = 0
30 END IF


40 IF a < 1 THEN
   a = a + 1
50 ELSEIF a > 0 THEN
   a = 0
   ELSEIF a = 0 THEN
   a = -1
60 END IF


REM now with no labels nor line numbers

IF a < 1 THEN
   a = a + 1
ELSEIF a > 0 THEN
   a = 0
END IF


IF a < 1 THEN
   a = a + 1
ELSEIF a > 0 THEN
   a = 0
   ELSEIF a = 0 THEN
   a = -1
END IF
