DIM a$ AS String

FUNCTION editStringFN(pos as Uinteger, newLetter$ as String) AS String
	DIM stringToEdit$
    stringToEdit$(pos)=newLetter$
    RETURN stringToEdit$
END FUNCTION

a$=editStringFN(1, "i")
