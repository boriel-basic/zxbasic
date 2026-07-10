; val.asm (zx81sd) — VAL(a$): convierte texto a numero en coma flotante
;
; Sustituye a zx48k/runtime/val.asm, que usa VAL de la ROM del Spectrum:
; ademas de convertir el texto a numero, la ROM real vuelve a meter la
; cadena en el interprete de BASIC y la evalua como una expresion completa
; (por eso en un Spectrum real VAL("2+2") funciona y da 4). Esa parte vive
; en el escaner de lineas de BASIC de la ROM, un subsistema aparte del
; calculador (no portado aqui).
;
; Esta version soporta solo un LITERAL DECIMAL simple: signo opcional,
; digitos, y un punto decimal opcional seguido de mas digitos. NO evalua
; expresiones (VAL("2+2") no funciona; VAL("2.5") o VAL("-13") si). Es el
; uso habitual de VAL(INPUT(...)) para leer numeros tecleados por el
; usuario. Cualquier caracter no numerico corta el parseo en ese punto
; (el resto de la cadena se ignora), en vez de dar un error.
;
; El numero se construye acumulando digito a digito con el propio
; calculador ya portado (fp_calc.asm): valor = valor*10 + digito, y al
; final se divide entre 10^(numero de decimales) si hubo parte fraccionaria.

#include once <mem/free.asm>
#include once <stackf.asm>

    push namespace core

; --- Variables de trabajo (no reentrante, uso transitorio durante VAL) -----
VAL_PTR:        defw 0      ; puntero al siguiente caracter a leer
VAL_LEN:        defw 0      ; caracteres restantes por leer
VAL_STRPTR:     defw 0      ; puntero original a la cadena (para liberarla)
VAL_FREE_FLAG:  defb 0      ; 1 si hay que liberar la cadena al terminar
VAL_NEG:        defb 0      ; 1 si el numero es negativo
VAL_INFRAC:     defb 0      ; 1 si ya se paso el punto decimal
VAL_DECIMALS:   defb 0      ; numero de digitos leidos tras el punto decimal

VAL:
    ; Entrada: HL = direccion de a$ (2 bytes de longitud + datos)
    ;          A  = 1 si hay que liberar a$ al terminar (no es variable)
    ; Salida:  A EDCB = numero en punto flotante (via __FPSTACK_POP)
    PROC

    LOCAL VAL_EMPTY
    LOCAL VAL_LOOP
    LOCAL VAL_GOT_SIGN
    LOCAL VAL_NOT_DOT
    LOCAL VAL_DIGIT
    LOCAL VAL_DIGIT_ADVANCE
    LOCAL VAL_DONE
    LOCAL VAL_DIV_LOOP
    LOCAL VAL_NOT_NEG
    LOCAL VAL_EMPTY_SKIP
    LOCAL VAL_NO_FREE
    LOCAL PUSH_DIGIT

    ld   (VAL_FREE_FLAG), a
    ld   a, h
    or   l
    jp   z, VAL_EMPTY       ; cadena NULL -> 0 (jp: VAL_EMPTY queda lejos)

    ld   (VAL_STRPTR), hl

    ld   e, (hl)
    inc  hl
    ld   d, (hl)
    inc  hl                 ; DE = longitud de la cadena
    ld   (VAL_LEN), de
    ld   (VAL_PTR), hl      ; HL = inicio del texto

    xor  a
    ld   (VAL_NEG), a
    ld   (VAL_INFRAC), a
    ld   (VAL_DECIMALS), a

    ld   hl, (VAL_LEN)
    ld   a, h
    or   l
    jp   z, VAL_DONE        ; cadena vacia -> 0

    ld   hl, (VAL_PTR)
    ld   a, (hl)
    cp   '-'
    jr   nz, VAL_GOT_SIGN
    ld   a, 1
    ld   (VAL_NEG), a
    inc  hl
    ld   (VAL_PTR), hl
    ld   de, (VAL_LEN)
    dec  de
    ld   (VAL_LEN), de
VAL_GOT_SIGN:

    ; acumulador FP = 0
    xor  a
    ld   e, a
    ld   d, a
    ld   c, a
    ld   b, a
    call __FPSTACK_PUSH

VAL_LOOP:
    ld   hl, (VAL_LEN)
    ld   a, h
    or   l
    jp   z, VAL_DONE

    ld   hl, (VAL_PTR)
    ld   a, (hl)

    cp   '.'
    jr   nz, VAL_NOT_DOT
    ld   a, 1
    ld   (VAL_INFRAC), a
    jr   VAL_DIGIT_ADVANCE  ; el punto no cuenta como digito, solo avanza

VAL_NOT_DOT:
    cp   '0'
    jp   c, VAL_DONE
    cp   '9' + 1
    jp   nc, VAL_DONE

VAL_DIGIT:
    sub  '0'                ; A = digito 0-9
    push af

    ld   a, 10
    call PUSH_DIGIT
    rst  28h
    defb $04                ;;multiply
    defb $38                ;;end-calc

    pop  af
    call PUSH_DIGIT
    rst  28h
    defb $0F                ;;addition
    defb $38                ;;end-calc

    ld   a, (VAL_INFRAC)
    or   a
    jr   z, VAL_DIGIT_ADVANCE
    ld   hl, VAL_DECIMALS
    inc  (hl)

VAL_DIGIT_ADVANCE:
    ld   hl, (VAL_PTR)
    inc  hl
    ld   (VAL_PTR), hl
    ld   hl, (VAL_LEN)
    dec  hl
    ld   (VAL_LEN), hl
    jp   VAL_LOOP

VAL_DONE:
    ld   a, (VAL_DECIMALS)
    or   a
    jr   z, VAL_NOT_NEG
    ld   b, a
VAL_DIV_LOOP:
    push bc
    ld   a, 10
    call PUSH_DIGIT
    rst  28h
    defb $05                ;;division
    defb $38                ;;end-calc
    pop  bc
    djnz VAL_DIV_LOOP

VAL_NOT_NEG:
    ld   a, (VAL_NEG)
    or   a
    jr   z, VAL_EMPTY_SKIP
    rst  28h
    defb $1B                ;;negate
    defb $38                ;;end-calc
VAL_EMPTY_SKIP:

    call __FPSTACK_POP      ; A EDCB = resultado

    push af
    push de
    push bc
    ld   a, (VAL_FREE_FLAG)
    or   a
    jr   z, VAL_NO_FREE
    ld   hl, (VAL_STRPTR)
    call __MEM_FREE
VAL_NO_FREE:
    pop  bc
    pop  de
    pop  af
    ret

VAL_EMPTY:
    xor  a
    ld   e, a
    ld   d, a
    ld   c, a
    ld   b, a
    jp   __FPSTACK_POP

; --- Apila A (0-255) como entero pequeño positivo ---------------------------
PUSH_DIGIT:
    ld   d, a
    xor  a
    ld   e, a
    ld   c, a
    ld   b, a
    jp   __FPSTACK_PUSH

    ENDP

    pop namespace
