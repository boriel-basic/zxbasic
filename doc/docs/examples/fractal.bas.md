#Fractal.bas

```
Program: fractal.bas by @Britlion
```


```
#define width 256
#define height 192

DIM x,y as FIXED
DIM xstart,xstep,ystart,ystep as FIXED
DIM xend,yend as FIXED
DIM z,zi,newz,newzi as FIXED
DIM colour as byte
DIM iter as uInteger
DIM col as uInteger
DIM i,k as uByte
DIM j as uInteger
dim inset as uByte

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

border 0
paper 0
ink 7
CLS

for i=0 to ( height -1 )/2 +1

        for j=0 to width -1
            z=0
            zi=0
            inset=1
                for k=0 to iter
                    ';z^2=(a+bi)*(a+bi) = a^2+2abi-b^2
                    newz=(z*z)-(zi*zi)+x
                    newzi=2*z*zi+y
                    z=newz
                    zi=newzi
                   
                    if (z*z)+(zi*zi) > 4 then
                        inset=0
                        colour=k
                        goto screen
                    END IF
                next k
               
screen:

                if NOT inset then
                    if colour BAND 1 THEN
                        plot j,i
                        plot j,192-i
                    END IF
                end if
                   
                x=x+xstep
         next j
               
        y=y+ystep
        x=xstart

print at 23,0;CAST(uinteger,i)*200/height;"%"
next i

BEEP 1,1
PAUSE 0
```
