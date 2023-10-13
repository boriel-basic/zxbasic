# Distance.bas

This calculates an approximation for the distance formula **r=`SQR`(x<sup>2</sup> + y<sup>2</sup>)**,
based on two parameters, `x` and `y`. The return value is not guaranteed to be accurate -
and indeed can be as high as 10% inaccurate as x and y approach 255 (the upper limit for input).
The return value is an integer - chosen because screen is 256 pixels wide, and the diagonal across the screen
is bigger than 1 byte can hold.

If you need accurate results, you should go with `iSqrt` or `fSqrt` from this library.

For speed, this can't be beaten, however.

Comparing -
`answer = distance(i, j)` against
`answer = iSqrt(i * i + j * j)` shows over a range of `i` and `j` `1..250`:

 * distance 8.98 seconds<br />
   iSqrt 50.1 seconds

Distance is definitely faster, if you're willing to accept the greater inaccuracy (you probably are).

By the by - standard floating point square root:

 * `fSqrt` function: 44 minutes (2625.14 seconds)
 * `SQR` (ROM) - 122 minutes. (7336.86 seconds)

Shows how awful that ROM SQR routine really is...

Formula is: in a right angle triangle with sides A and B, and hypotenuse H, as an estimate of length of H,
it returns (A + B) - (half the smallest of A and B) - (1/4 the smallest of A and B) + (1/16 the smallest of A and B)


```
FUNCTION fastcall distance (a as ubyte, b as ubyte) as uInteger

REM returns a fast approximation of SQRT (a^2 + b^2) - the distance formula, generated from taylor series expansion.
REM This version fundamentally by Alcoholics Anonymous, improving on Britlion's earlier version - which itself
REM was suggested, with thanks, by NA_TH_AN.

asm
 POP HL ;' return address
 ;' First parameter in A
 POP BC ;' second parameter -> B
 PUSH HL ;' put return back

 ;' First find out which is bigger - A or B.
 cp b
 ld c,b
 jr nc, distance_AisMAX
 ld c,a

distance_AisMAX:

 ;' c = MIN(a,b)

 srl c     ;' c = MIN/2
 sub c   ;' a = A - MIN/2
 srl c    ;' c = MIN/4
 sub c   ;' a = A - MIN/2 - MIN/4
 srl c
 srl c    ;' c = MIN/16
 add a,c   ;' a = A - MIN/2 - MIN/4 + MIN/16
 add a,b   ;' a = A + B - MIN/2 - MIN/4 + MIN/16

 ld l,a
 ld h,0     ;' hl = result
 ret nc
 inc h      ;' catch 9th bit
END ASM
END FUNCTION
```
