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

A **For...Next** loop initializes _iterator_ to _startvalue_, then executes the _sentences_, incrementing _iterator_ by 
_stepvalue_ until it reaches or exceeds _endvalue_. If _stepvalue_ is not explicitly given it will set to 1.

##Examples

```
REM Counts from 1 to 10
FOR i = 1 TO 10: PRINT i: NEXT
```

### Counts downwards
```
FOR i = 10 TO 1 STEP -1: PRINT i: NEXT
```

### Loops using odd numbers
```
FOR i = 1 TO 10 STEP 2: PRINT i: NEXT
```

##Differences From Sinclair Basic
* The variable name after the NEXT statement is not required.

* Note that variable types can cause issues with ZX Basic For...Next Loops. If the upper limit of the iterator exceeds
the upper limit of the variable type, the loop may not complete.
For example:
```
DIM i as UByte

FOR i = 1 to 300
    PRINT i
NEXT i
```

Clearly, since the largest value a byte can hold is 255, it's not possible for i in the above example to exceed 300.
The variable will "wrap around" to 0 and as a result, the loop will not ever terminate.
This can happen in much more subtle ways when `STEP` is used.
There has to be "room" within the variable type for the iterator to exceed the terminator when it is being
incremented by <step> amounts.

For example, this loop will neved end

```
DIM i as UInteger

FOR i = 65000 TO 65500 STEP 100
 ...
NEXT i
```

This loop will never end. `UInteger` type allows values in the range `[0..65535]` so apparently it's ok, because
65500 fits in it. However `STEP` is 100, so 65500 + 100 = 65600 which fall out if such range. There will be an
_overflow_ and the variable `i` will take the value 64 and the loop will continue.

##See Also

* [WHILE ... END WHILE](while.md)
* [DO ... LOOP](do.md)
* [IF ... END IF](if.md)
* [EXIT](exit.md)
* [CONTINUE](continue.md)
* [TO](to.md)
* [Sinclair Basic Manual](http://www.worldofspectrum.org/ZXBasicManual/zxmanchap4.html)
