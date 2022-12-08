# Operators

Operators in ZX Basic can be arithmetical, logical and [bitwise](bitwiselogic.md) ones.
For bitwise operators checks the [Bitwise Operators](bitwiselogic.md) page.

## Arithmetic Operators  

Arithmetic operators are _left associative_ (like in Sinclair BASIC) and have the same _precedence_. The following are a list of arithmetic operators (lower precedence operators appears first): 

* `+`, `-` (Addition, Subtraction)<br />Operator `+` (addition) can also be used with 
[strings](types.md#strings) to perform string concatenation.

* `*`, `/`, `mod` (Multiplication, Division and Modulo)

>**Note**: `mod` operator returns the _modulus_ (the reminder) of x / y.<br />
>E.g. _12 `mod` 5_ = 2. It does not exist in Sinclair BASIC. 


## Exponentiation  

* `^` (Power). x`^`y returns _x <sup>y</sup>_

>**Note**: Unlike Sinclair Basic, this operator is **right associative**.

This is the usual behavior in mathematics. So in ZX BASIC:

```
2^3^2 = 2^(3^2) = 512
```

(notice the right associative parenthesis), whilst in Sinclair BASIC, 

```
2^3^2 = (2^3)^2 = 64
```
 

which is _wrong_. If in doubt, use always parenthesis to enforce the desired evaluation order.

## Logical Operators  

Logicals operators are like in ZX Spectrum Basic. Their result can be either _False_ (which is represented with 0)
or _True_, which might be any other value. <u>Don't expect _True_ value number to be always **1**</u>.
If you need 0/1 values for boolean evaluations, use `--strict-boolean` [compiler option](zxb.md#Command Line Options).
This might add a little overhead to boolean evaluations, tough. 

Operator arguments must be numbers and the result is an unsigned byte value. For binary operators, 
if arguments are of different types they are [converted](cast.md) to a common type before being evaluated: 

### Table of Logical Operators

#### AND
 Performs the _Logical Conjunction_ and returns _TRUE_ if and only if both arguments are _TRUE_. 
 
| a  | b  | result |
|:----:|:----:|:------:|
|  False  | False |  False |
|  False  | True  |  False |
|  True  | False |  False |
|  True  | True  |  True |
---

#### OR
Performs the _Logical Disjunction_ and returns _TRUE_ if any of the arguments is _TRUE_.

| a  | b  | result |
|:----:|:----:|:------:|
|  False  | False |  False |
|  False  | True  |  True |
|  True  | False |  True |
|  True  | True  |  True |
---

#### XOR
Performs a logical XOR and returns TRUE if one of the arguments is true and one of the arguments is false.
In essence, returns true if ONLY one of the arguments is true. 

| a  | b  | result |
|:----:|:----:|:------:|
|  False  | False |  False |
|  False  | True  |  True |
|  True  | False |  True |
|  True  | True  |  False |
---

#### NOT
Performs the _Logical Negation_ and returns _TRUE_ if the arguments is _False_ and vice versa.
 
| a  | result |
|:----:|:----:|
|  False  | True |
|  True  | False |

## @ Operator
Address operator

