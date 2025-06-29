# STDCALL

`StdCall` is used to indicate that a `FUNCTION` or `SUB` will receive all its parameters in the stack, following the
_Standard Calling Convention_.

The standard calling convention pushes all the function's parameters into the stack in _reverse order_. For 8bit values,
since Z80 stack register SP register is word-aligned, the parameter is pushed as a 16 bit value, in the high 8 bits
(the Z80 ASM instruction `push af` pushes `A` register in the higher part, and `F` register -flags- in the lower).

Return value for functions is placed in registers, based on the function return type:
* 8 bit returns should be in the A register
* 16 bit returns should be in HL <br/>
  Also for `String` values, the memory address of the string.
* 32 bit returns should be in DEHL
* 40 bit FLOAT returns should be in CDEHL.

`STDCALL` is used by default in any function if no calling convention is used.

The stack is automatically cleaned upon function termination.

## Example

```vbnet
REM These two declarations are equivalent

SUB STDCALL Hello
  PRINT "HELLO WORLD!"
END SUB

SUB Hello
  PRINT "HELLO WORLD!"
END SUB
```

## See Also

 * [FASTCALL](fastcall.md)
