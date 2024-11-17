DIM dummy as UInteger

sub printerPutString(char$ as string)
    let dummy = LEN(char$)
end sub

sub Frame(strg$ as string)
    printerPutString(strg$)
end sub

Frame("OK")
