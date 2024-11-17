DIM dummy As UInteger

sub printerPutString(char$ as string)
   let dummy = LEN(char$)
end sub

sub Frame()
    strg$ = "OK"
    printerPutString(strg$)
end sub

Frame()
