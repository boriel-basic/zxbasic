DIM index As UInteger
DIM TABLENAMES(10) AS STRING

SUB Test (value As String, BYREF HighScoreNames() AS STRING)
    LET HighScoreNames(index) = value
END SUB

Test("OUP", TABLENAMES)
