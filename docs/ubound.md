#UBOUND

##Syntax

```
UBound(<array variable>)
UBound(<array variable>, <dimension>)
```

##Description

Returns the array upper bound of the given <dimension>. If the <dimension> is not specified, it defaults to 0.
If the specified <dimension> is 0, then total number of dimensions is returned.

##Examples

```
DIM a(3 TO 5, 2 TO 8)
PRINT UBound(a, 2) : REM Prints 8
PRINT Ubound(a) : REM Prints 2, because it has 2 dimensions
```


The result is always a 16bit integer value.

If the <dimension> is 0, then the number of dimension in the array is returned
(useful to guess the number of dimensions of an array):

```
DIM a(3 TO 5, 2 TO 8)
PRINT UBound(a, 0): REM Prints 2, since 'a' has 2 dimensions
```


##Remarks

* This function does not exists in Sinclair BASIC.

##See also

* [DIM](dim.md)
* [LBOUND](lbound.md)
