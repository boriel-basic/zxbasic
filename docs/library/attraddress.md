#AttrAddress

#attrAdress(x,y)  

This function will return the address of the byte that controls
the attributes of a given X-Y print position co-ordinate. 


```
FUNCTION attrAddress (x as uByte, y as uByte) as uInteger 
'This function returns the memory address of the Character Position 
'x,y in the attribute screen memory. 
'Adapted from code by Jonathan Cauldwell. 
'Rebuilt for ZX BASIC by Britlion from NA_TH_AN's fourspriter, with permission. 

Asm 
         ld      a,(IX+7)  ;ypos
         rrca
         rrca
         rrca              ; Multiply by 32
         ld      l,a       ; Pass to L
         and     3         ; Mask with 00000011
         add     a,88      ; 88 * 256 = 22528 - start of attributes.
         ld      h,a       ; Put it in the High Byte
         ld      a,l       ; We get y value *32
         and     224       ; Mask with 11100000
         ld      l,a       ; Put it in L
         ld      a,(IX+5)  ; xpos 
         add     a,l       ; Add it to the Low byte
         ld      l,a       ; Put it back in L, and we're done. HL=Address.

End Asm 
END FUNCTION
```

## Usage 

Example: 
```
poke attrAddress(10,10),43 
```

Will change the attributes of print position 10, 10 to 43 - (magenta ink on cyan paper)
