#LBOUND

##Syntax

```
LBound(<array variable>)
LBound(<array variable>, <dimension>)
```


##Description

Returns the array lower bound of the given <dimension>. If the <dimension> is not specified, it defaults to 1.
If the specified <dimension> is 0, then total number of dimensions is returned.

##Examples

```
DIM a(3 TO 5, 2 TO 8)
PRINT LBound(a, 2) : REM Prints 2
PRINT Lbound(a) : REM Prints 3, because dimension defaults to 1
```


The result is always a 16bit integer value.

If the <dimension> is 0, then the number of dimension in the array is returned
(useful to guess the number of dimensions of an array):

```
DIM a(3 TO 5, 2 TO 8)
PRINT LBound(a, 0): REM Prints 2, since 'a' has 2 dimensions
```


##Remarks

* This function does not exists in Sinclair BASIC.

##See also

* [DIM](dim.md)
* [UBOUND](ubound.md)
