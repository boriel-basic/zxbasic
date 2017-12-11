#define spriteX (dataSprite+11)
#define spriteY (dataSprite+12)
#define spriteOldX (dataSprite+28)
#define spriteOldY (dataSprite+29)
#define spriteEsp0 (dataSprite+30)
#define spriteTimer (dataSprite+26)

DIM dataSprite as Uinteger
poke UInteger spriteTimer,0
poke spriteX, peek (spriteOldX)
poke spriteY, peek (spriteOldY)
poke spriteEsp0,0

