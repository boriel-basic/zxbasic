# FASTCALL

Fastcall is used to indicate that an assembly function should be jumped into with registers already set. 

* If the function takes a Byte (or uByte) parameter, then the A register will be set with this parameter. 
* If it takes an Integer (or uInteger) parameter, then the HL register will be set with the value of that parameter on entry to the function. 
* If it takes a Long (or uLong), or fixed  parameter, then the DE and HL registers will hold the 32 bit value of the parameter.
* If it takes a float type parameter, then the registers C, DE and HL will hold the five bytes for that value.

Return is automatic based on the function return type in the same way:
* 8 bit returns should be in the A register
* 16 bit returns should be in HL
* 32 bit returns should be in DEHL
* 40 bit FLOAT returns should be in CDEHL.

Fastcall should ONLY be used with functions that take a single parameter. If you use more than one parameter, you'll have to deal with the stack (SP register) and restore it to the previous it had before your function was called.

**Example:**

```
FUNCTION FASTCALL whatLetter (A as uByte) as uByte
   Asm
             PROC
             LOCAL DATA, START
             JP START
   DATA:     DEFB "A Man, A Plan, A Canal, Panama"
   START:    LD HL,DATA
             LD D,0
             LD E,A
             ADD HL,DE
             LD A,(HL)
             ENDP
   End Asm
END FUNCTION
```

The above function, when called with `whatLetter(<value>)` will return the `<value>`-th letter of the phrase
`"A Man, A Plan, A Canal, Panama"`.

### Notes
* Note that the A register already contains <value> when the inline assembly is reached.
* Note that we do NOT need to put a ret opcode on the end of the assembly. The compiler will do that for us.
