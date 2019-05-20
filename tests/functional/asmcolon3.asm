
    cp 3 : jr z,nextjump 
    ld hl,data : jp overjump
nextjump:
    ld hl,0
overjump:
    ld a,(hl)

data:

