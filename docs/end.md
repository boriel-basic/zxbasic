# END


##Syntax
```
END [<value>]
```

Terminates execution and returns to the Operating System (i.e. to the Sinclair
BASIC interpreter). An optional value can be used (defaults to 0 if not specified)
that will be returned to the OS.

```basic
PRINT "HELLO WORLD"
END 32: REM The value 32 will be returned to the OS
```

End is also a keyword used to close [scopes](scope.md) in [FUNCTION](function.md) and [SUB](sub.md)
and compound sentences in [IF](if.md), [WHILE](while.md).
