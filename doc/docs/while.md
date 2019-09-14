#WHILE ... END WHILE

**WHILE** is a _compound_ statement used to perform loops. The code within a **WHILE** statement will repeat _while_ the given condition is _true_.
If the given _condition_ is false the first time the inner _sentences_ are _never_ executed.

##Syntax
```
 WHILE expression
    sentences
 END WHILE
```
or

```
 WHILE expression
    sentences
 WEND
```
The first form is preferred.

##Examples
```
While a < b
   Let a = a + 1
   Poke a, 0
End While
```


An infinite loop:
```
While 1
  REM An infinite loop. This will issue a warning
  Print "Hello world!"
End While
```


**Note**: For infinite loops use [DO ... LOOP](do.md)

##Remarks
* This statement does not exist in Sinclair Basic.
* **WHILE** can also be used with [DO ... LOOP](do.md).

##See Also
* [IF ... END IF](if.md)
* [DO ... LOOP](do.md)
* [FOR ... NEXT](for.md)
* [EXIT](exit.md)
* [CONTINUE](continue.md)
