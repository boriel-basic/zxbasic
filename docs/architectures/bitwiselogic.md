#BitWiseLogic

ZX Basic allows Bit Manipulation (bitwise), on every integer type (from 8 to 32 bits).

{| cellspacing="7" style="background-color: rgb(40, 40, 64); border: 2px solid rgb(119, 119, 119); width: 1133px; height: 291px;" class="roundedborders"
|+ **Table of BITWISE OPERATORS** 
|-
! bAND
! bOR
! bNOT 
! bXOR<br>
|- valign="top" style="background-color: rgb(144, 21, 0); color: rgb(208, 208, 208);" class="roundedborders"
| Performs the _Bitwise Conjunction_ and returns 1 for every bit if and only if both bits are 1. 
<br> 

{| align="center" style="color: green; background-color: rgb(255, 255, 204); border: 1px solid rgb(0, 0, 0);" class="roundedborders"
|+ <span style="color: yellow;">a **AND** b</span> 
|-
! a 
! b 
! Result
|-
| 0 
| 0
| 0
|-
| 0
| 1 
| 0
|-
| 1
| 0
| 0
|-
| 1
| 1
| 1
|}

<br> 

| Performs the _Bitwise Disjunction_ and returns 1 if any of the arguments is 1. 
<br> 

{| align="center" style="color: green; background-color: rgb(255, 255, 204); border: 1px solid rgb(0, 0, 0);" class="roundedborders"
|+ <span style="color: yellow;">a **OR** b</span> 
|-
! a 
! b 
! Result
|-
| 0
| 0 
| 0
|-
| 0 
| 1 
| 1
|-
| 1 
| 0 
| 1
|-
| 1 
| 1 
| 1
|}

<br> 

| Performs the _Logical Negation_ and returns _TRUE_ if the arguments is _False_ and vice versa. 
<br> 

{| align="center" style="color: green; background-color: rgb(255, 255, 204); border: 1px solid rgb(0, 0, 0);" class="roundedborders"
|+ <span style="color: yellow;">**NOT** a</span> 
|-
! a 
! Result
|-
| False 
| True
|-
| True 
| False
|}

<br> 

| 
Performs a logical XOR and returns TRUE if one of the arguments is true and one of the arguments is false. In essense, returns true if ONLY one of the arguments is true. 

<br> 

{| align="center" style="color: green; background-color: rgb(255, 255, 204); border: 1px solid rgb(0, 0, 0);" class="roundedborders"
|+ <span style="color: yellow;">a **XOR** b</span> 
|-
| a<br> 
| b<br> 
| Result<br>
|-
| False<br> 
| False<br> 
| False<br>
|-
| False<br> 
| True<br> 
| True<br>
|-
| True<br> 
| False<br> 
| True<br>
|-
| True<br> 
| True<br> 
| False<br>
|}


