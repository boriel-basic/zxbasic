Dim dataSprite,dw1,dw2,dw3,tB as Uinteger

const enemiSprites as Uinteger= 49152
const enemiBullets as Uinteger =63872
const dirGraficoHuevo as Uinteger=enemiSprites+(91*86)
const dirGraficoBoom as Uinteger=enemiSprites+(97*86)

const tablaSprites as Uinteger=30720
const bulletToloStatus as UInteger= tablaSprites+1024
const bulletToloCol as UInteger= tablaSprites+1024+4
const bulletToloFila as UInteger= tablaSprites+1024+5
const bulletToloFace as UInteger= tablaSprites+1024+8

poke bulletToloStatus,%00000100
poke (dataSprite), %01010011
poke (dataSprite+11),peek ((dataSprite+4))*6
poke (dataSprite+12),peek ((dataSprite+5))*4
poke UInteger (dataSprite+17),dirGraficoHuevo
poke (dataSprite+30),peek ((dataSprite+8))
poke UInteger bulletToloCol,0

poke (dataSprite+6),0
poke (dataSprite+7),0
poke (dataSprite+8),0
poke (dataSprite+21),0
poke (dataSprite+22),0
poke (dataSprite+23),0
poke (dataSprite+24),0
