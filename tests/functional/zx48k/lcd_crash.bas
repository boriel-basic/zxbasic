dim tiles(16) as uinteger
tiles(0)=@void
tiles(1)=tiles(0)

dim monsterx as byte
void:

sub putChars(x as Uinteger, y as Uinteger, a as Ubyte, b as Ubyte, addr as Uinteger)
end Sub

sub settile(x as ubyte,y as ubyte,tile as ubyte)
   putChars(monsterx*3,monsterx*3,3,3,@void)
end sub
settile(0, 0, 0)
