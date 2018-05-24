 
#define width 256
#define height 192
 
DIM x,y AS FIXED
DIM xstart,xstep,ystart,ystep AS FIXED
DIM xend,yend AS FIXED
DIM z,zi,newz,newzi AS FIXED
DIM colour AS BYTE
DIM iter AS UINTEGER
DIM col AS UINTEGER
DIM i,k AS UBYTE
DIM j AS UINTEGER
DIM inset AS UBYTE
 
 
 
xstart=-1.6
xend=0.65
ystart=-1.15
yend=-ystart
iter=24
 
xstep=(xend-xstart)/width
ystep=(yend-ystart)/height
 
'Main loop
x=xstart
y=ystart
 
BORDER 0
PAPER 0
INK 7
CLS
 
FOR i=0 TO ( height -1 )/2 +1
        FOR j=0 TO width -1
            z=0
            zi=0
            inset=1
                FOR k=0 TO iter
                    ';z^2=(a+bi)*(a+bi) = a^2+2abi-b^2
                    newz=(z*z)-(zi*zi)+x
                    newzi=2*z*zi+y
                    z=newz
                    zi=newzi
                   
                    IF (z*z)+(zi*zi) > 4 THEN
                        inset=0
                        colour=k
                        GOTO screen
                    END IF
                NEXT k
               
screen:               
                IF NOT inset THEN
                    IF colour BAND 1 THEN
                        PLOT j,i
                        PLOT j,192-i
                    END IF
                END IF
                   
                x=x+xstep
         NEXT j
               
        y=y+ystep
        x=xstart
PRINT AT 23,0;CAST(UINTEGER,i)*200/height;"%"
NEXT i
                           
BEEP 1,1
PAUSE 0

