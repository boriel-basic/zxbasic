DIM dummy as UInteger
LET strg$ = "OK"

sub printerPutString(char$ as string)
   LET dummy = LEN(char$)
end sub

sub Frame()
    printerPutString(strg$)
end sub

Frame()
