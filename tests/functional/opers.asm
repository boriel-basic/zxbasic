


x EQU 0x1234

db x % 256
db x & 0xFF
db x >> 8
dw x << 8
dw x | 0xFF00 
dw x ~ 0x1234
dw x ~ x

db y % 256
db y & 0xFF
db y >> 8
dw y << 8
dw y | 0xFF00 
dw y ~ 0x1234
dw y ~ y

y:

