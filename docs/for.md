#FOR ... NEXT

##Syntax

```
 FOR iterator = startvalue TO endvalue [ STEP stepvalue ]
   [ sentences ]
 NEXT [ iterator ]
```
##Parameters

* _iterator_: a variable identifier that is used to iterate from an initial value to an end value.
* _datatype_: If specified, the variable iterator will automatically be declared with the type datatype.
* _startvalue_: an expression that denotes the starting value of the iterator.
* _endvalue_: an expression used to compare with the value of the iterator.
* _stepvalue_: an expression that is added to the iterator after every iteration.

##Description

A **For...Next** loop initializes _iterator_ to _startvalue_, then executes the _sentences_, incrementing _iterator_ by _stepvalue_ until it reaches or exceeds _endvalue_. If _stepvalue_ is not explicitly given it will set to 1.

##Examples

```
FOR i = 1 TO 10: PRINT i: NEXT
```

##Differences From Sinclair Basic
* The variable name after the NEXT statement is not required.

* Note that variable types can cause issues with ZX Basic For...Next Loops. If the upper limit of the iterator exceeds the upper limit of the variable type, the loop may not complete.
For example:
```
DIM i as UByte

FOR i = 1 to 300
    PRINT i
NEXT i
```

Clearly, since the largest value a byte can hold is 255, it's not possible for i in the above example to exceed 300.
The variable will "wrap around" to 0 and as a result, the loop will not ever terminate.
This can happen in much more subtle ways when STEP is used.
There has to be "room" within the variable type for the iterator to exceed the terminator when it is being
incremented by "STEP" amounts.

##See Also

* [WHILE ... END WHILE](while.md)
* [DO ... LOOP](do.md)
* [IF ... END IF](if.md)
* [EXIT](exit.md)
* [CONTINUE](continue.md)
* [Sinclair Basic Manual](http://www.worldofspectrum.org/ZXBasicManual/zxmanchap4.html)
