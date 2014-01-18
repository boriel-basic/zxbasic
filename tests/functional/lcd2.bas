' A bug encountered by LCD

function lset(a as byte, setchar as byte, length as ubyte) as Ubyte
   while a<length
      a=setchar+a
   wend
   return a
end function

print at 0,30;"HP";at 1,30;lset(str(peek(adr)),"0",2);at 2,30;"OF";at 3,30;lset(str(peek(adr+3)),"0",2)

