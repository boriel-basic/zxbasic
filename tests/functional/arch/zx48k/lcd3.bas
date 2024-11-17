' A bug encountered by LCD
DIM z as String

function lset(a$ as string,setchar$ as string,length as ubyte) as string
   while len(a$)<length
      a$=setchar$+a$
   wend
   return a$
end function

LET z = lset(str(peek(adr)),"0",2)
LET z = lset(str(peek(adr+3)),"0",2)
