# IF ... END IF

**IF** is a very powerful control flow sentence that allows you to _make decisions_ under specified contitions.

## Syntax
```
 IF expression [THEN] sentences [: END IF]

```
or 

```
 IF expression [THEN]
    sentences
 [ELSEIF expression [THEN] sentences]
 [ELSEIF expression [THEN] sentences]
  ...
 [ELSE sentences]
 END IF

```
### Examples
```
IF a < 5 THEN PRINT "A is less than five" ELSE PRINT "A is greater than five"
```


Sentences might be in multiple lines:

```
If a < 5 Then
    Print "A is less than five"
    a = a + 5 
Else
    Print "A is greater than five"
End If
```


Since **IF** is a _sentence_, it can be nested; however, remember that _every_ **IF** _must be closed with_ **END IF** when the line is split after **THEN** (mutiline **IF**):
```
If a < 5 Then
    Print "A is less than five"
    If a > 2 Then
        Print "A is less than five but greater than 2"
    End If
Else If a < 7 Then
        Print "A is greater or equal to five, but lower than 7"
    Else
        Print "A is greater than five"
    End If
End If
```


## Using ELSEIF
In the example above, you see that nesting an **IF** inside another one could be somewhat verbose and error prone. It's better to use 
the **ELSEIF** construct. So the previous example could be rewritten as:

```
If a < 5 Then
    Print "A is less than five"
    If a > 2 Then
        Print "A is less than five but greater than 2"
    End If
ElseIf a < 7 Then
    Print "A is greater or equal to five, but lower than 7"
Else
    Print "A is greater than five"
End If
```


## Remarks
* This sentence is **extended** allowing now multiline IFs and also compatible with the Sinclair BASIC version.
* Starting from version 1.8 onwards the trailing **END IF** is not mandatory for single-line IFs, for compatibility with Sinclair BASIC
* The **THEN** keyword can be omitted, but keep in mind this might reduce code legibility.

## See Also
* [WHILE ... END WHILE](while.md)
* [DO ... LOOP](do.md)
* [FOR ... NEXT](for.md)

