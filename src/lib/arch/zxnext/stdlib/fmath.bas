' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2024
' Contributed by Britlion
' ----------------------------------------------------------------

#pragma once

#pragma push(case_insensitive)
#pragma case_insensitive = True


FUNCTION fSin(num as FIXED) as FIXED
    DIM quad as byte
    DIM est1,dif as uByte

    'This change made now that MOD works with FIXED types.
    'This is much faster than the repeated subtraction method for large angles (much > 360)
    'while having some tiny rounding errors that should not significantly affect our results.
    'Note that the result may be positive or negative still, and for SIN(360) might come out
    'fractionally above 360 (which would cause issued) so the below code still is required.

    IF num >= 360 THEN
      num = num MOD 360
    ELSEIF num < 0 THEN
      num = 360 - ABS(num) MOD 360
    END IF

    IF num>180 then
      quad=-1
      num=num-180
    ELSE
      quad=1
    END IF

    IF num>90 then num=180-num

    num=num/2
    dif=num : rem Cast to byte loses decimal
    num=num-dif : rem so this is just the decimal bit


    est1=PEEK (@sinetable+dif)
    dif=PEEK (@sinetable+dif+1)-est1 : REM this is just the difference to the next up number.

    num=est1+(num*dif): REM base +interpolate to the next value.

    return (num/255)*quad


    sinetable:
    asm
    DEFB 000,009,018,027,035,044,053,062
    DEFB 070,079,087,096,104,112,120,127
    DEFB 135,143,150,157,164,171,177,183
    DEFB 190,195,201,206,211,216,221,225
    DEFB 229,233,236,240,243,245,247,249
    DEFB 251,253,254,254,255,255
    end asm
END FUNCTION

FUNCTION fCos(num as FIXED) as FIXED
    return fSin(90-num)
END FUNCTION

FUNCTION fTan(num as FIXED) as FIXED
    return fSin(num)/fSin(90-num)
END FUNCTION

REM Fast floating Point Square Root Function
REM Adapted and modified for Boriel's ZX BASIC
REM By Britlion

FUNCTION FASTCALL fSqrt (radicand as FLOAT) as FLOAT
    ASM
      push namespace core

      ; FLOAT value arrives in A ED CB
      ; A is the exponent.
      AND   A               ; Test for zero argument
      RET   Z               ; Return with zero.

      ;Strictly we should test the number for being negative and quit if it is.
      ;But let's assume we like imaginary numbers, hmm?
      ; If you'd rather break it change to a jump to an error below.
      ;BIT   7,E          ; Test the bit.
      ;JR    NZ,REPORT       ; back to REPORT_A
                            ; 'Invalid argument'
      RES 7,E               ; Now it's a positive number, no matter what.

      call __FPSTACK_PUSH   ; Okay, We put it on the calc stack. Stack contains ABS(x)

      ;   Halve the exponent to achieve a good guess.(accurate with .25 16 64 etc.)

                            ; Remember, A is the exponent.
      XOR   $80             ; toggle sign of exponent
      SRA   A               ; shift right, bit 7 unchanged.
      INC   A               ;
      JR    Z,ASIS          ; forward with say .25 -> .5
      JP    P,ASIS          ; leave increment if value > .5
      DEC   A               ; restore to shift only.

    ASIS:
      XOR   $80             ; restore sign.
      call __FPSTACK_PUSH   ; Okay, NOW we put the guess on the stack
      rst  28h   ; ROM CALC    ;;guess,x
      DEFB $C3              ;;st-mem-3
      DEFB $02              ;;delete

    SQRLOOP:
      DEFB  $31             ;;duplicate
      DEFB  $E3             ;;get-mem-3
      DEFB  $C4             ;;st-mem-4
      DEFB  $05             ;;div
      DEFB  $E3             ;;get-mem-3
      DEFB  $0F             ;;addition
      DEFB  $A2             ;;stk-half
      DEFB  $04             ;;multiply
      DEFB  $C3             ;;st-mem-3
      DEFB  $E4             ;;get-mem-4
      DEFB  $03             ;;subtract
      DEFB  $2A             ;;abs
      DEFB  $37             ;;greater-0
      DEFB  $00             ;;jump-true

      DEFB  SQRLOOP - $     ;;to sqrloop

      DEFB  $02             ;;delete
      DEFB  $E3             ;;get-mem-3
      DEFB  $38             ;;end-calc              sqr x.

      jp __FPSTACK_POP

      pop namespace

    END ASM
END FUNCTION

#pragma pop(case_insensitive)
