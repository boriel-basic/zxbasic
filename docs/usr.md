# USR

## Syntax


```
USR(<address>)
USR(<string value>)
```

## Description

This function exist for the sole compatibility with Sinclair BASIC. It's not needed in ZX Basic.

If used with a numeric argument, it will jump to the given memory address and start executing the machine code from there.
To return the control to BASIC, a `ret` instruction must be executed. The value of the BC register will be used as the
value (uInteger) returned by the function.

If used with a string argument, it will return the UDG (User Defined Graphic) memory address of the first character of the string.
For example, for the `\A` UDG, `USR "a"` will return the address of it. This function is case insensitive.

Returned value type is [UInteger](types.md#Integral).

## Examples

To call a machine code routine:
```
REM Uses USR to invoke a machine code routine
PRINT "BC register returned "; USR @myRoutine
END

myRoutine:
Asm
ld bc, 1234
ret
End Asm
```

To work with UDG:
```
REM Creates an UDG with Horizontal lines
FOR i = 0 TO 7:
    POKE USR "a" + i, 255 * (i MOD 2)
NEXT i
PRINT "\A is the UDG A"
```

## Remarks

* This function is 100% Sinclair BASIC Compatible

## See Also

* [CODE](code.md)
