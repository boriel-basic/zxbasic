; -----------------------------------------------------------
; vim: et:ts=4:sw=4:ruler: 
;
; DRAW an arc using ZX ROM algorithm.
; DRAW x, y, r => r = Arc in radians

; r parameter in A ED BC register
; X, and Y parameter in high byte on top of the stack

#include once <error.asm>
#include once <plot.asm>
#include once <stackf.asm>
#include once <draw.asm>

; Ripped from the ZX Spectrum ROM

DRAW3:
        PROC 
        LOCAL STACK_TO_BC
        LOCAL STACK_TO_A
        LOCAL COORDS
        LOCAL L2477
        LOCAL L2420
        LOCAL L2439
        LOCAL L245F
        LOCAL L23C1
        LOCAL L2D28
        LOCAL SUM_C, SUM_B

L2D28   EQU 02D28h
COORDS  EQU 5C7Dh
STACK_TO_BC EQU 2307h
STACK_TO_A  EQU 2314h

        exx
        ex af, af'              ;; Preserves ARC
        pop hl
        pop de
        ex (sp), hl             ;; CALLEE
        push de
        call __FPSTACK_I16      ;; X Offset
        pop hl
        call __FPSTACK_I16      ;; Y Offset
        exx
        ex af, af'
        call __FPSTACK_PUSH     ;; R Arc
        
;   Now enter the calculator and store the complete rotation angle in mem-5 

        RST     28H             ;; FP-CALC      x, y, A.
        DEFB    $C5             ;;st-mem-5      x, y, A.

;   Test the angle for the special case of 360 degrees.

        DEFB    $A2             ;;stk-half      x, y, A, 1/2.
        DEFB    $04             ;;multiply      x, y, A/2.
        DEFB    $1F             ;;sin           x, y, sin(A/2).
        DEFB    $31             ;;duplicate     x, y, sin(A/2),sin(A/2)
        DEFB    $30             ;;not           x, y, sin(A/2), (0/1).
        DEFB    $30             ;;not           x, y, sin(A/2), (1/0).
        DEFB    $00             ;;jump-true     x, y, sin(A/2).

        DEFB    $06             ;;forward to L23A3, DR-SIN-NZ
                                ;;if sin(r/2) is not zero.

;   The third parameter is 2*PI (or a multiple of 2*PI) so a 360 degrees turn
;   would just be a straight line.  Eliminating this case here prevents 
;   division by zero at later stage.

        DEFB    $02             ;;delete        x, y.
        DEFB    $38             ;;end-calc      x, y.
        JP      L2477

; ---

;   An arc can be drawn.

;; DR-SIN-NZ
        DEFB    $C0             ;;st-mem-0      x, y, sin(A/2).   store mem-0
        DEFB    $02             ;;delete        x, y.

;   The next step calculates (roughly) the diameter of the circle of which the 
;   arc will form part.  This value does not have to be too accurate as it is
;   only used to evaluate the number of straight lines and then discarded.
;   After all for a circle, the radius is used. Consequently, a circle of 
;   radius 50 will have 24 straight lines but an arc of radius 50 will have 20
;   straight lines - when drawn in any direction.
;   So that simple arithmetic can be used, the length of the chord can be 
;   calculated as X+Y rather than by Pythagoras Theorem and the sine of the
;   nearest angle within reach is used.

        DEFB    $C1             ;;st-mem-1      x, y.             store mem-1
        DEFB    $02             ;;delete        x.

        DEFB    $31             ;;duplicate     x, x.
        DEFB    $2A             ;;abs           x, x (+ve).
        DEFB    $E1             ;;get-mem-1     x, X, y.
        DEFB    $01             ;;exchange      x, y, X.
        DEFB    $E1             ;;get-mem-1     x, y, X, y.
        DEFB    $2A             ;;abs           x, y, X, Y (+ve).
        DEFB    $0F             ;;addition      x, y, X+Y.
        DEFB    $E0             ;;get-mem-0     x, y, X+Y, sin(A/2).
        DEFB    $05             ;;division      x, y, X+Y/sin(A/2).
        DEFB    $2A             ;;abs           x, y, X+Y/sin(A/2) = D.

;    Bring back sin(A/2) from mem-0 which will shortly get trashed.
;    Then bring D to the top of the stack again.

        DEFB    $E0             ;;get-mem-0     x, y, D, sin(A/2).
        DEFB    $01             ;;exchange      x, y, sin(A/2), D.

;   Note. that since the value at the top of the stack has arisen as a result
;   of division then it can no longer be in integer form and the next re-stack
;   is unnecessary. Only the Sinclair ZX80 had integer division.

        ;;DEFB    $3D             ;;re-stack      (unnecessary)

        DEFB    $38             ;;end-calc      x, y, sin(A/2), D.

;   The next test avoids drawing 4 straight lines when the start and end pixels
;   are adjacent (or the same) but is probably best dispensed with.

        LD      A,(HL)          ; fetch exponent byte of D.
        CP      $81             ; compare to 1
        JR      NC,L23C1        ; forward, if > 1,  to DR-PRMS

;   else delete the top two stack values and draw a simple straight line.

        RST     28H             ;; FP-CALC
        DEFB    $02             ;;delete
        DEFB    $02             ;;delete
        DEFB    $38             ;;end-calc      x, y.

        JP      L2477           ; to LINE-DRAW

; ---

;   The ARC will consist of multiple straight lines so call the CIRCLE-DRAW
;   PARAMETERS ROUTINE to pre-calculate sine values from the angle (in mem-5)
;   and determine also the number of straight lines from that value and the
;   'diameter' which is at the top of the calculator stack.

;; DR-PRMS
L23C1:  CALL    247Dh           ; routine CD-PRMS1

                                ; mem-0 ; (A)/No. of lines (=a) (step angle)
                                ; mem-1 ; sin(a/2) 
                                ; mem-2 ; -
                                ; mem-3 ; cos(a)                        const
                                ; mem-4 ; sin(a)                        const
                                ; mem-5 ; Angle of rotation (A)         in
                                ; B     ; Count of straight lines - max 252.

        PUSH    BC              ; Save the line count on the machine stack.

;   Remove the now redundant diameter value D.

        RST     28H             ;; FP-CALC      x, y, sin(A/2), D.
        DEFB    $02             ;;delete        x, y, sin(A/2).

;   Dividing the sine of the step angle by the sine of the total angle gives
;   the length of the initial chord on a unary circle. This factor f is used
;   to scale the coordinates of the first line which still points in the 
;   direction of the end point and may be larger.

        DEFB    $E1             ;;get-mem-1     x, y, sin(A/2), sin(a/2)
        DEFB    $01             ;;exchange      x, y, sin(a/2), sin(A/2)
        DEFB    $05             ;;division      x, y, sin(a/2)/sin(A/2)
        DEFB    $C1             ;;st-mem-1      x, y. f.
        DEFB    $02             ;;delete        x, y.

;   With the factor stored, scale the x coordinate first.

        DEFB    $01             ;;exchange      y, x.
        DEFB    $31             ;;duplicate     y, x, x.
        DEFB    $E1             ;;get-mem-1     y, x, x, f.
        DEFB    $04             ;;multiply      y, x, x*f    (=xx)
        DEFB    $C2             ;;st-mem-2      y, x, xx.
        DEFB    $02             ;;delete        y. x.

;   Now scale the y coordinate.

        DEFB    $01             ;;exchange      x, y.
        DEFB    $31             ;;duplicate     x, y, y.
        DEFB    $E1             ;;get-mem-1     x, y, y, f
        DEFB    $04             ;;multiply      x, y, y*f    (=yy)

;   Note. 'sin' and 'cos' trash locations mem-0 to mem-2 so fetch mem-2 to the 
;   calculator stack for safe keeping.

        DEFB    $E2             ;;get-mem-2     x, y, yy, xx.

;   Once we get the coordinates of the first straight line then the 'ROTATION
;   FORMULA' used in the arc loop will take care of all other points, but we
;   now use a variation of that formula to rotate the first arc through (A-a)/2
;   radians. 
;   
;       xRotated = y * sin(angle) + x * cos(angle)
;       yRotated = y * cos(angle) - x * sin(angle)
;
 
        DEFB    $E5             ;;get-mem-5     x, y, yy, xx, A.
        DEFB    $E0             ;;get-mem-0     x, y, yy, xx, A, a.
        DEFB    $03             ;;subtract      x, y, yy, xx, A-a.
        DEFB    $A2             ;;stk-half      x, y, yy, xx, A-a, 1/2.
        DEFB    $04             ;;multiply      x, y, yy, xx, (A-a)/2. (=angle)
        DEFB    $31             ;;duplicate     x, y, yy, xx, angle, angle.
        DEFB    $1F             ;;sin           x, y, yy, xx, angle, sin(angle)
        DEFB    $C5             ;;st-mem-5      x, y, yy, xx, angle, sin(angle)
        DEFB    $02             ;;delete        x, y, yy, xx, angle

        DEFB    $20             ;;cos           x, y, yy, xx, cos(angle).

;   Note. mem-0, mem-1 and mem-2 can be used again now...

        DEFB    $C0             ;;st-mem-0      x, y, yy, xx, cos(angle).
        DEFB    $02             ;;delete        x, y, yy, xx.

        DEFB    $C2             ;;st-mem-2      x, y, yy, xx.
        DEFB    $02             ;;delete        x, y, yy.

        DEFB    $C1             ;;st-mem-1      x, y, yy.
        DEFB    $E5             ;;get-mem-5     x, y, yy, sin(angle)
        DEFB    $04             ;;multiply      x, y, yy*sin(angle).
        DEFB    $E0             ;;get-mem-0     x, y, yy*sin(angle), cos(angle)
        DEFB    $E2             ;;get-mem-2     x, y, yy*sin(angle), cos(angle), xx.
        DEFB    $04             ;;multiply      x, y, yy*sin(angle), xx*cos(angle).
        DEFB    $0F             ;;addition      x, y, xRotated.
        DEFB    $E1             ;;get-mem-1     x, y, xRotated, yy.
        DEFB    $01             ;;exchange      x, y, yy, xRotated.
        DEFB    $C1             ;;st-mem-1      x, y, yy, xRotated.
        DEFB    $02             ;;delete        x, y, yy.

        DEFB    $E0             ;;get-mem-0     x, y, yy, cos(angle).
        DEFB    $04             ;;multiply      x, y, yy*cos(angle).
        DEFB    $E2             ;;get-mem-2     x, y, yy*cos(angle), xx.
        DEFB    $E5             ;;get-mem-5     x, y, yy*cos(angle), xx, sin(angle).
        DEFB    $04             ;;multiply      x, y, yy*cos(angle), xx*sin(angle).
        DEFB    $03             ;;subtract      x, y, yRotated.
        DEFB    $C2             ;;st-mem-2      x, y, yRotated.

;   Now the initial x and y coordinates are made positive and summed to see 
;   if they measure up to anything significant.

        DEFB    $2A             ;;abs           x, y, yRotated'.
        DEFB    $E1             ;;get-mem-1     x, y, yRotated', xRotated.
        DEFB    $2A             ;;abs           x, y, yRotated', xRotated'.
        DEFB    $0F             ;;addition      x, y, yRotated+xRotated.
        DEFB    $02             ;;delete        x, y. 

        DEFB    $38             ;;end-calc      x, y. 

;   Although the test value has been deleted it is still above the calculator
;   stack in memory and conveniently DE which points to the first free byte
;   addresses the exponent of the test value.

        LD      A,(DE)          ; Fetch exponent of the length indicator.
        CP      $81             ; Compare to that for 1

        POP     BC              ; Balance the machine stack

        JP      C,L2477         ; forward, if the coordinates of first line
                                ; don't add up to more than 1, to LINE-DRAW 

;   Continue when the arc will have a discernable shape.

        PUSH    BC              ; Restore line counter to the machine stack.

;   The parameters of the DRAW command were relative and they are now converted 
;   to absolute coordinates by adding to the coordinates of the last point 
;   plotted. The first two values on the stack are the terminal tx and ty 
;   coordinates.  The x-coordinate is converted first but first the last point 
;   plotted is saved as it will initialize the moving ax, value. 

        RST     28H             ;; FP-CALC      x, y.
        DEFB    $01             ;;exchange      y, x.
        DEFB    $38             ;;end-calc      y, x.

        LD      A,(COORDS)      ;; Fetch System Variable COORDS-x
        CALL    L2D28           ;; routine STACK-A

        RST     28H             ;; FP-CALC      y, x, last-x.

;   Store the last point plotted to initialize the moving ax value.

        DEFB    $C0             ;;st-mem-0      y, x, last-x.
        DEFB    $0F             ;;addition      y, absolute x.
        DEFB    $01             ;;exchange      tx, y.
        DEFB    $38             ;;end-calc      tx, y.

        LD      A,(COORDS + 1)  ; Fetch System Variable COORDS-y
        CALL    L2D28           ; routine STACK-A

        RST     28H             ;; FP-CALC      tx, y, last-y.

;   Store the last point plotted to initialize the moving ay value.

        DEFB    $C5             ;;st-mem-5      tx, y, last-y.
        DEFB    $0F             ;;addition      tx, ty.

;   Fetch the moving ax and ay to the calculator stack.

        DEFB    $E0             ;;get-mem-0     tx, ty, ax.
        DEFB    $E5             ;;get-mem-5     tx, ty, ax, ay.
        DEFB    $38             ;;end-calc      tx, ty, ax, ay.

        POP     BC              ; Restore the straight line count.

; -----------------------------------
; THE 'CIRCLE/DRAW CONVERGENCE POINT'
; -----------------------------------
;   The CIRCLE and ARC-DRAW commands converge here. 
;
;   Note. for both the CIRCLE and ARC commands the minimum initial line count 
;   is 4 (as set up by the CD_PARAMS routine) and so the zero flag will never 
;   be set and the loop is always entered.  The first test is superfluous and
;   the jump will always be made to ARC-START.

;; DRW-STEPS
L2420:  DEC     B               ; decrement the arc count (4,8,12,16...).            

        ;JR      Z,L245F         ; forward, if zero (not possible), to ARC-END

        JP      L2439           ; forward to ARC-START

; --------------
; THE 'ARC LOOP'
; --------------
;
;   The arc drawing loop will draw up to 31 straight lines for a circle and up 
;   251 straight lines for an arc between two points. In both cases the final
;   closing straight line is drawn at ARC_END, but it otherwise loops back to 
;   here to calculate the next coordinate using the ROTATION FORMULA where (a)
;   is the previously calculated, constant CENTRAL ANGLE of the arcs.
;
;       Xrotated = x * cos(a) - y * sin(a)
;       Yrotated = x * sin(a) + y * cos(a)
;
;   The values cos(a) and sin(a) are pre-calculated and held in mem-3 and mem-4 
;   for the duration of the routine.
;   Memory location mem-1 holds the last relative x value (rx) and mem-2 holds
;   the last relative y value (ry) used by DRAW.
;
;   Note. that this is a very clever twist on what is after all a very clever,
;   well-used formula.  Normally the rotation formula is used with the x and y
;   coordinates from the centre of the circle (or arc) and a supplied angle to 
;   produce two new x and y coordinates in an anticlockwise direction on the 
;   circumference of the circle.
;   What is being used here, instead, is the relative X and Y parameters from
;   the last point plotted that are required to get to the current point and 
;   the formula returns the next relative coordinates to use. 

;; ARC-LOOP
L2425:  RST     28H             ;; FP-CALC      
        DEFB    $E1             ;;get-mem-1     rx.
        DEFB    $31             ;;duplicate     rx, rx.
        DEFB    $E3             ;;get-mem-3     cos(a)
        DEFB    $04             ;;multiply      rx, rx*cos(a).
        DEFB    $E2             ;;get-mem-2     rx, rx*cos(a), ry.
        DEFB    $E4             ;;get-mem-4     rx, rx*cos(a), ry, sin(a). 
        DEFB    $04             ;;multiply      rx, rx*cos(a), ry*sin(a).
        DEFB    $03             ;;subtract      rx, rx*cos(a) - ry*sin(a)
        DEFB    $C1             ;;st-mem-1      rx, new relative x rotated.
        DEFB    $02             ;;delete        rx.

        DEFB    $E4             ;;get-mem-4     rx, sin(a).
        DEFB    $04             ;;multiply      rx*sin(a)
        DEFB    $E2             ;;get-mem-2     rx*sin(a), ry.
        DEFB    $E3             ;;get-mem-3     rx*sin(a), ry, cos(a).
        DEFB    $04             ;;multiply      rx*sin(a), ry*cos(a).
        DEFB    $0F             ;;addition      rx*sin(a) + ry*cos(a).
        DEFB    $C2             ;;st-mem-2      new relative y rotated.
        DEFB    $02             ;;delete        .
        DEFB    $38             ;;end-calc      .  

;   Note. the calculator stack actually holds   tx, ty, ax, ay
;   and the last absolute values of x and y 
;   are now brought into play.
;
;   Magically, the two new rotated coordinates rx and ry are all that we would
;   require to draw a circle or arc - on paper!
;   The Spectrum DRAW routine draws to the rounded x and y coordinate and so 
;   repetitions of values like 3.49 would mean that the fractional parts 
;   would be lost until eventually the draw coordinates might differ from the 
;   floating point values used above by several pixels.
;   For this reason the accurate offsets calculated above are added to the 
;   accurate, absolute coordinates maintained in ax and ay and these new 
;   coordinates have the integer coordinates of the last plot position 
;   ( from System Variable COORDS ) subtracted from them to give the relative 
;   coordinates required by the DRAW routine.

;   The mid entry point.

;; ARC-START
L2439:  PUSH    BC              ; Preserve the arc counter on the machine stack.

;   Store the absolute ay in temporary variable mem-0 for the moment.

        RST     28H             ;; FP-CALC      ax, ay.
        DEFB    $C0             ;;st-mem-0      ax, ay.
        DEFB    $02             ;;delete        ax.

;   Now add the fractional relative x coordinate to the fractional absolute
;   x coordinate to obtain a new fractional x-coordinate.

        DEFB    $E1             ;;get-mem-1     ax, xr.
        DEFB    $0F             ;;addition      ax+xr (= new ax).  
        DEFB    $31             ;;duplicate     ax, ax.
        DEFB    $38             ;;end-calc      ax, ax. 

        LD      A,(COORDS)       ; COORDS-x      last x    (integer ix 0-255)
        CALL    L2D28           ; routine STACK-A

        RST     28H             ;; FP-CALC      ax, ax, ix.
        DEFB    $03             ;;subtract      ax, ax-ix  = relative DRAW Dx.

;   Having calculated the x value for DRAW do the same for the y value.

        DEFB    $E0             ;;get-mem-0     ax, Dx, ay.
        DEFB    $E2             ;;get-mem-2     ax, Dx, ay, ry.
        DEFB    $0F             ;;addition      ax, Dx, ay+ry (= new ay).
        DEFB    $C0             ;;st-mem-0      ax, Dx, ay.
        DEFB    $01             ;;exchange      ax, ay, Dx,
        DEFB    $E0             ;;get-mem-0     ax, ay, Dx, ay.
        DEFB    $38             ;;end-calc      ax, ay, Dx, ay.

        LD      A,(COORDS + 1)  ; COORDS-y      last y (integer iy 0-175)
        CALL    L2D28           ; routine STACK-A

        RST     28H             ;; FP-CALC      ax, ay, Dx, ay, iy.
        DEFB    $03             ;;subtract      ax, ay, Dx, ay-iy ( = Dy).
        DEFB    $38             ;;end-calc      ax, ay, Dx, Dy.

        CALL    L2477           ; Routine DRAW-LINE draws (Dx,Dy) relative to
                                ; the last pixel plotted leaving absolute x 
                                ; and y on the calculator stack.
                                ;               ax, ay.

        POP     BC              ; Restore the arc counter from the machine stack.

        DJNZ    L2425           ; Decrement and loop while > 0 to ARC-LOOP

; -------------
; THE 'ARC END'
; -------------

;   To recap the full calculator stack is       tx, ty, ax, ay.

;   Just as one would do if drawing the curve on paper, the final line would
;   be drawn by joining the last point plotted to the initial start point 
;   in the case of a CIRCLE or to the calculated end point in the case of 
;   an ARC.
;   The moving absolute values of x and y are no longer required and they
;   can be deleted to expose the closing coordinates.

;; ARC-END
L245F:  RST     28H             ;; FP-CALC      tx, ty, ax, ay.
        DEFB    $02             ;;delete        tx, ty, ax.
        DEFB    $02             ;;delete        tx, ty.
        DEFB    $01             ;;exchange      ty, tx.
        DEFB    $38             ;;end-calc      ty, tx.

;   First calculate the relative x coordinate to the end-point.

        LD      A,($5C7D)       ; COORDS-x
        CALL    L2D28           ; routine STACK-A

        RST     28H             ;; FP-CALC      ty, tx, coords_x.
        DEFB    $03             ;;subtract      ty, rx.

;   Next calculate the relative y coordinate to the end-point.

        DEFB    $01             ;;exchange      rx, ty.
        DEFB    $38             ;;end-calc      rx, ty.

        LD      A,($5C7E)       ; COORDS-y
        CALL    L2D28           ; routine STACK-A

        RST     28H             ;; FP-CALC      rx, ty, coords_y
        DEFB    $03             ;;subtract      rx, ry.
        DEFB    $38             ;;end-calc      rx, ry.
;   Finally draw the last straight line.
L2477:
        call    STACK_TO_BC     ;;Pops x, and y, and stores it in B, C
        ld      hl, (COORDS)    ;;Calculates x2 and y2 in L, H

        rl      e               ;; Rotate left to carry
        ld      a, c
        jr      nc, SUM_C
        neg
SUM_C:
        add     a, l
        ld      l, a            ;; X2

        rl      d               ;; Low sign to carry
        ld      a, b
        jr      nc, SUM_B
        neg
SUM_B:
        add     a, h
        ld      h, a
        jp      __DRAW          ;;forward to LINE-DRAW (Fastcalled)

        ENDP
