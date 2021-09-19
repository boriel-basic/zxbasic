sub printerPutString(char$ as string)
   print char$
end sub

sub Frame(strg$ as string)
    printerPutString(strg$)
end sub

Frame("OK")
