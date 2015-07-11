
LET strg$ = "OK"

sub printerPutString(char$ as string)
   print char$
end sub

sub Frame()
    printerPutString(strg$)
end sub

Frame()
