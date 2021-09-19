
SUB test2
   POKE 0, 2
END SUB


SUB test
label:
   GOTO label
   test2
END sub
