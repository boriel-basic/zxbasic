; test jump relative out of range
label1:
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0 ,0
dw 0, 0, 0, 0, 0, 0, 0
db 1
jr label1

