REM Should not emit a warning (unreachable code) 
REM ... due to label in line 4

FUNCTION distance () as uByte
  return 1
mylabel:
END FUNCTION

distance

