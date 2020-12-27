

#define x(a, b) a ## b

x( A ,  B  )

REM Should not be concatenated out of define body
A ## B

