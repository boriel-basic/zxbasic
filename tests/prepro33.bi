asm
   EX DE,HL
   PUSH DE ; save our address

   LD L,(IX+8) ; data address
   LD H,(IX+9)
   EX AF,AF'
   LD A,4   ;row counter
   EX AF,AF'
   BLPutCharLoop:
   LD B,8
  
   BLPutCharOneCharLoop:
   XOR A; LD A,0
   LD C,A
   
   ; gets screen address in DE, and bytes address in HL. Copies the row to the screen
   LDI  ; also decrements B.
   LDI
   LDI
   LDI ; 4 bytes copied.
   LD A,C
   ADD A,E ;(A should be -4)
   LD E,A
   INC D
   LD A,B
   OR A
   JP NZ,BLPutCharOneCharLoop
   
   EX AF,AF'
   DEC A
   JR Z, BLPutCharsEnd  ; We've done all 4 rows.
   EX AF,AF'
end asm

