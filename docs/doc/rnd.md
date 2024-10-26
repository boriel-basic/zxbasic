# RND

## Syntax

```
rnd()
rnd
```


## Description

Returns a number of type float in the range [0, 1) (i.e. 0 <= RND < 1), based on a random seed (see [RANDOMIZE](randomize.md)).

## Examples


```
REM Function to a random number in the range [first, last), or {first <= x < last}.
Function rnd_range (first As Double, last As Double) As Float
    Function = Rnd * (last - first) + first
End Function

REM seed the random number generator, so the sequence is not the same each time
Randomize

REM prints a random number in the range [0, 1], or {0 <= x < 1}.
Print Rnd

REM prints a random number in the range [0, 10], or  {0 <= x < 10}.
Print Rnd * 10

REM prints a random integer number in the range [1, 11), or  {1 <= x < 11}.
REM with integers, this is equivalent to [1, 10], or {1 <= n <= 10}.
Print Int(Rnd * 10) + 1

REM prints a random integer number in the range [69, 421], or {69 <= x < 421}.
REM this is equivalent to [69, 420], or {69 <= n <= 420}.
Print Int(rnd_range(69, 421))
```

## Remarks

ZX BASIC RND is much faster than Sinclair BASIC RND, and produces different random sequences.

Its randomness is also much better (try plotting points at random x,y coords,
and they look really random whilst in Sinclair BASIC diagonal lines begin to appear:
this means there's a correlation between x, y points hence not very random).

Also, Sinclair BASIC RND has a periodicity of 2^16 (65536), whilst ZX BASIC RND has a periodicity of 2^32 (4,294,967,296).

## See also

* [RANDOMIZE](randomize.md)
