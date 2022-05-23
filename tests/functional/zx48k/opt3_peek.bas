#define spriteStatus (dataSprite)
#define spriteTimer (dataSprite+26)

dim d1 as ubyte
dim dataSprite as Uinteger

const variablesGlobales as UInteger= 24326
const tictac as UInteger= (variablesGlobales+2)

poke spriteTimer,peek(spriteTimer)+peek(tictac)
d1=peek(spriteTimer)+peek (tictac)
