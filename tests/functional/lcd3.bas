' A bug encountered by LCD

function lset(a$ as string,setchar$ as string,length as ubyte) as string
   while len(a$)<length
      a$=setchar$+a$
   wend
   return a$
end function

print at 0,30;"HP";at 1,30;lset(str(peek(adr)),"0",2);at 2,30;"OF";at 3,30;lset(str(peek(adr+3)),"0",2)

