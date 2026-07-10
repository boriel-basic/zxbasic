; VECTORS — Tabla de vectores RST del Z80 para ZX81 + SD81 Booster
;
; Ocupa $0000-$00FF (primer bloque de la zona de sistema).
; Reemplaza la ROM del ZX81 (bloque 0 remapeado a página 8 por el stage 1).
;
; Tras el remapeo de bloque 0, el stage 1 salta a $0100 (stage 2 bootstrap).
; El vector RST 0 redirige allí también, por si algo fuerza un reset software.

    push namespace core

    org $0000

; $0000 — RST 0 / Reset software: salta al stage 2
    jp  $0100

    defs $0008 - $, $00

; $0008 — RST $08 (handler de errores Spectrum): redirige a __ERROR
    jp  __ERROR

    defs $0010 - $, $00

; $0010 — RST $10 (PRINT A en Spectrum): no usado, cuelga de forma segura
    di
    halt

    defs $0018 - $, $00

; $0018 — RST $18: no usado
    di
    halt

    defs $0020 - $, $00

; $0020 — RST $20: no usado
    di
    halt

    defs $0028 - $, $00

; $0028 — RST $28 (FP calculator Spectrum): stub, no debe llegarse aquí
;          con __ZXB_NO_FLOAT activo el compilador no genera RST $28
    di
    halt

    defs $0030 - $, $00

; $0030 — RST $30: no usado
    di
    halt

    defs $0038 - $, $00

; $0038 — RST $38 (IM1 interrupt): DI permanente, nunca debería llegar
    di
    halt

    defs $0066 - $, $00

; $0066 — NMI handler: NMI desactivadas por el cargador BASIC (modo FAST),
;          pero el vector debe existir por si acaso
    retn

    defs $0100 - $, $00     ; relleno hasta inicio del stage 2 en $0100

    pop namespace
