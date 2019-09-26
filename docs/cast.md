#CAST

##Syntax

```
CAST (type,numeric value)
CAST (type,variable)
CAST (type,function(data))
```

##Description

Returns a value of the [type](types.md) specified with a value equivalent to the item specified, if that is possible.

##Remarks

* This function can lose precision if used indiscriminately.
For example, CAST(Integer,PI) returns 3, losing precision on the value of PI.
* This function is NOT Sinclair Compatible.

##See also

* [Types](types.md)


