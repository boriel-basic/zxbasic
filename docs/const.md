# CONST

## Syntax


```
CONST <varname> [AS <type>] = <value>
```


## Description

**CONST** declares a non-modifable variable.

`<type>` can be something like `Integer`, `Byte`, `Float`, etc.
See the list of [available types](types.md). If type is not specified,
`Float` will be used, unless you use a modifier like `$` or `%`.

## Examples


```
CONST screenAddress as uInteger = 16384
```
