#ScrAddress

This function returns the address in screen memory of the TOP line of the character in print position X-Y. 
Remember that the next line will be 256 bytes further on, and the 3rd line 256 further again and so forth,
for 7 more lines.

```
FUNCTION scrAddress(x as uByte, y as uByte) as Uinteger
asm 
; This function returns the address into HL of the screen address
; x,y in character grid notation. 
; Original code was extracted by BloodBaz
     ; x Arrives in A, y is in stack.
     and     31
     ld      l,a
     ld      a,(IX+7) ; Y value
     ld      d,a
     and     24
     add     a,64
     ld      h,a
     ld      a,d
     and     7
     rrca
     rrca
     rrca
     or      l
     ld      l,a
end asm
END FUNCTION


FUNCTION attrAddress (x as uByte, y as uByte) as uInteger               
';; This function returns the memory address of the Character Position
';; x,y in the attribute screen memory.
';; Adapted from code by Jonathan Cauldwell.

asm
     ld      a,(IX+7)        ;ypos
     rrca
     rrca
     rrca               ; Multiply by 32
     ld      l,a        ; Pass to L
     and     3          ; Mask with 00000011
     add     a,88       ; 88 * 256 = 22528 - start of attributes.
     ld      h,a        ; Put it in the High Byte
     ld      a,l        ; We get y value *32
     and     224        ; Mask with 11100000
     ld      l,a        ; Put it in L
     ld      a,(IX+5)   ; xpos 
     add     a,l        ; Add it to the Low byte
     ld      l,a        ; Put it back in L, and we're done. HL=Address.
end asm
END FUNCTION
```

Examples of use (though more likely to be used as parameters to other screen handling functions):


```
Print scrAddress(8,15)
Print attrAddress(8,15)
```
