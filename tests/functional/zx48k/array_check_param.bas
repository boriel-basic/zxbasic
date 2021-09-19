#pragma arrayCheck=true

REM array check should do nohing on parameters
REM because we don't known the array limits

function pickString$(listOfStrings() as string ) as string
    return listOfStrings(choice)
end function
