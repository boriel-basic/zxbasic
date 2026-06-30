; PAGING — Rutinas de paginación de memoria del SD81 Booster
; Puerto $E7h: mapeador de memoria en bloques de 8KB
;
; Modo simple (hasta 256KB, 32 páginas):
;   OUT ($E7h), A   con  A = (página << 3) | bloque
;
; Modo completo (hasta 512KB, 64 páginas):
;   OUT (C), A      con  A = bloque (0-7), B = página (0-63), C = $E7h
;
; Los bloques 0-3 ($0000-$7FFF) son ejecutables.
; Los bloques 4-7 ($8000-$FFFF) son solo datos (sin MC45).
; Los bloques 6-7 deben ser consistentes con el HFILE en modo normal del ZX81;
; en modo Superfast HiRes Spectrum la FPGA ignora esa restricción.

    push namespace core

SD81_PAGE_PORT  EQU $E7     ; Puerto del mapeador de memoria

; PAGE_SET_SIMPLE — Asigna página a bloque (modo simple, hasta 32 páginas)
; Entrada: A = bloque (0-7), B = página (0-31)
; Destruye: A, C
PAGE_SET_SIMPLE:
    ld   c, a               ; C = bloque
    ld   a, b
    sla  a
    sla  a
    sla  a                  ; A = página << 3
    or   c                  ; A = (página << 3) | bloque
    out  (SD81_PAGE_PORT), a
    ret

; PAGE_SET_FULL — Asigna página a bloque (modo completo, hasta 64 páginas)
; Entrada: A = bloque (0-7), B = página (0-63)
; Destruye: C
PAGE_SET_FULL:
    ld   c, SD81_PAGE_PORT
    out  (c), a             ; A = bloque, B = página
    ret

; PAGE_SET_SCREEN — Mapea la página de pantalla al bloque 6 ($C000)
; Entrada: B = número de página RAM dedicada a la pantalla
; Destruye: A, C
PAGE_SET_SCREEN:
    ld   a, 6               ; bloque 6 = $C000-$DFFF
    jp   PAGE_SET_FULL

; PAGE_SET_DATA — Mapea una página de datos al bloque 7 ($E000)
; Entrada: B = número de página
; Destruye: A, C
PAGE_SET_DATA:
    ld   a, 7               ; bloque 7 = $E000-$FFFF
    jp   PAGE_SET_FULL

    pop namespace
