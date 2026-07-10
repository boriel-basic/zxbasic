; draw3.asm (zx81sd) — DRAW en modo arco (DRAW x, y, angulo)
;
; Sustituye a zx48k/runtime/draw3.asm, que llama directamente a direcciones
; fijas de la ROM del Spectrum (STACK-A/STACK-BC en $2D28/$2D2Bh, STK-TO-A en
; $2314h, STK-TO-BC en $2307h, CD-PRMS1 en $247Dh) para nada de eso hay ROM
; mapeada en zx81sd. Aqui se usan las mismas rutinas, pero ya portadas como
; codigo propio en fp_calc.asm (Fases 1, 4 y 5). El resto del algoritmo (que
; es codigo bytecode del calculador: rst 28h + literales) es identico al
; original, ya que rst 28h ya apunta a nuestro CALCULATE propio.

#include once <error.asm>
#include once <plot.asm>
#include once <stackf.asm>
#include once <fp_calc.asm>
#include once <draw.asm>
#include once <sysvars.asm>

    push namespace core

DRAW3:
    PROC
    LOCAL L2477
    LOCAL L2420
    LOCAL L2439
    LOCAL L245F
    LOCAL L23C1
    LOCAL SUM_C, SUM_B
    LOCAL DR_SIN_NZ

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

    DEFB    (DR_SIN_NZ - $) & 0FFh
    ;;if sin(r/2) is not zero.

;   The third parameter is 2*PI (or a multiple of 2*PI) so a 360 degrees turn
;   would just be a straight line.  Eliminating this case here prevents
;   division by zero at later stage.

    DEFB    $02             ;;delete        x, y.
    DEFB    $38             ;;end-calc      x, y.
    JP      L2477

; ---

;   An arc can be drawn.

DR_SIN_NZ:
    DEFB    $C0             ;;st-mem-0      x, y, sin(A/2).   store mem-0
    DEFB    $02             ;;delete        x, y.

;   The next step calculates (roughly) the diameter of the circle of which the
;   arc will form part.

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

    DEFB    $E0             ;;get-mem-0     x, y, D, sin(A/2).
    DEFB    $01             ;;exchange      x, y, sin(A/2), D.

    DEFB    $38             ;;end-calc      x, y, sin(A/2), D.

;   The next test avoids drawing 4 straight lines when the start and end pixels
;   are adjacent (or the same).

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

;   The ARC will consist of multiple straight lines so call CD-PRMS1 to
;   pre-calculate sine values from the angle (in mem-5) and determine also
;   the number of straight lines from that value and the 'diameter' which
;   is at the top of the calculator stack.

#ifdef DRAW3_DEBUG
DRAW3_BP_PRMS:                  ; breakpoint: justo antes de llamar a CD-PRMS1
#endif
L23C1:  CALL    L247D           ; routine CD-PRMS1

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
;   the length of the initial chord on a unary circle.

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

;   'sin' and 'cos' trash locations mem-0 to mem-2 so fetch mem-2 to the
;   calculator stack for safe keeping.

    DEFB    $E2             ;;get-mem-2     x, y, yy, xx.

;   Rotate the first arc through (A-a)/2 radians.
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

;   mem-0, mem-1 and mem-2 can be used again now...

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
;   plotted.

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

L2420:
    DEC     B               ; decrement the arc count (4,8,12,16...).

    JP      L2439           ; forward to ARC-START

; --------------
; THE 'ARC LOOP'
; --------------

L2425:
#ifdef DRAW3_DEBUG
DRAW3_BP_ARCLOOP:               ; breakpoint: inicio de cada vuelta del bucle (rotacion)
#endif
    RST     28H             ;; FP-CALC
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

;; ARC-START
L2439:
#ifdef DRAW3_DEBUG
DRAW3_BP_ARCSTART:              ; breakpoint: calculo de Dx/Dy de cada segmento
#endif
    PUSH    BC              ; Preserve the arc counter on the machine stack.

    RST     28H             ;; FP-CALC      ax, ay.
    DEFB    $C0             ;;st-mem-0      ax, ay.
    DEFB    $02             ;;delete        ax.

    DEFB    $E1             ;;get-mem-1     ax, xr.
    DEFB    $0F             ;;addition      ax+xr (= new ax).
    DEFB    $31             ;;duplicate     ax, ax.
    DEFB    $38             ;;end-calc      ax, ax.

    LD      A,(COORDS)       ; COORDS-x      last x    (integer ix 0-255)
    CALL    L2D28           ; routine STACK-A

    RST     28H             ;; FP-CALC      ax, ax, ix.
    DEFB    $03             ;;subtract      ax, ax-ix  = relative DRAW Dx.

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

L245F:
#ifdef DRAW3_DEBUG
DRAW3_BP_ARCEND:                ; breakpoint: ultimo segmento hasta el punto final
#endif
    RST     28H             ;; FP-CALC      tx, ty, ax, ay.
    DEFB    $02             ;;delete        tx, ty, ax.
    DEFB    $02             ;;delete        tx, ty.
    DEFB    $01             ;;exchange      ty, tx.
    DEFB    $38             ;;end-calc      ty, tx.

;   First calculate the relative x coordinate to the end-point.

    LD      A,(COORDS)       ; COORDS-x
    CALL    L2D28           ; routine STACK-A

    RST     28H             ;; FP-CALC      ty, tx, coords_x.
    DEFB    $03             ;;subtract      ty, rx.

;   Next calculate the relative y coordinate to the end-point.

    DEFB    $01             ;;exchange      rx, ty.
    DEFB    $38             ;;end-calc      rx, ty.

    LD      A,(COORDS + 1)       ; COORDS-y
    CALL    L2D28           ; routine STACK-A

    RST     28H             ;; FP-CALC      rx, ty, coords_y
    DEFB    $03             ;;subtract      rx, ry.
    DEFB    $38             ;;end-calc      rx, ry.
;   Finally draw the last straight line.
L2477:
#ifdef DRAW3_DEBUG
DRAW3_BP_LINE:                  ; breakpoint: aqui B,C,D,E = linea que se va a dibujar
#endif
    call    L2307           ;;Pops x, and y, and stores it in B, C

#ifdef DRAW3_DEBUG
    push af
    push hl
    ld   a, (DRAW3_DEBUG_N)
    cp   16
    jr   nc, DRAW3_DEBUG_SKIP2
    ld   hl, (DRAW3_DEBUG_PTR)
    ld   (hl), b        ; Y magnitude
    inc  hl
    ld   (hl), c        ; X magnitude
    inc  hl
    ld   (hl), d        ; Y sign (bit7 via RL later)
    inc  hl
    ld   (hl), e        ; X sign (bit7 via RL later)
    inc  hl
    ld   a, (COORDS)
    ld   (hl), a        ; COORDS-x before this line
    inc  hl
    ld   a, (COORDS + 1)
    ld   (hl), a        ; COORDS-y before this line
    inc  hl
    ld   (DRAW3_DEBUG_PTR), hl
    ld   a, (DRAW3_DEBUG_N)
    inc  a
    ld   (DRAW3_DEBUG_N), a
DRAW3_DEBUG_SKIP2:
    pop  hl
    pop  af
#endif

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

#ifdef DRAW3_DEBUG
DRAW3_DEBUG_N:   defb 0
DRAW3_DEBUG_PTR: defw DRAW3_DEBUG_BUF
DRAW3_DEBUG_BUF: defs 16 * 6
#endif

    pop namespace
