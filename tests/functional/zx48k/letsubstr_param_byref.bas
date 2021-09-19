DIM a$ AS String

FUNCTION editStringFN(ByRef stringToEdit$ AS String, pos as Uinteger, newLetter$ as String) AS String
    stringToEdit$(pos)=newLetter$
    RETURN stringToEdit$
END FUNCTION

a$=editStringFN(a$, 1, "i")
