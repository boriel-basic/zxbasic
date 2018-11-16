1 BORDER 0: PAPER 0: INK 9: BRIGHT 1: CLS
10 LET spheres=2: IF spheres THEN DIM c(spheres,3): DIM r(spheres): DIM q(spheres)
20 FOR k=1 TO spheres: READ c(k,1),c(k,2),c(k,3),r: LET r(k)=r: LET q(k)=r*r: NEXT k

