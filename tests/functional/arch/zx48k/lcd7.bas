sub printerPutString(char$ as string)
   print char$
end sub

sub Frame()
    strg$ = "OK"
    printerPutString(strg$)
end sub

Frame()
