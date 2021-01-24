
SUB test2
   POKE 0, 2
END SUB


SUB test
label:
   test2
END sub

POKE UInteger 0, @label + 1

