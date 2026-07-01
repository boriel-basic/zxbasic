; CHARSET — Fuente de caracteres 8x8 compatible Spectrum
;
; 96 caracteres × 8 bytes, desde CHR$(32) hasta CHR$(127).
; Fichero externo: specfont.bin (debe estar en el mismo directorio).

    push namespace core

__ZX81SD_CHARSET:
    INCBIN "specfont.bin"

    pop namespace
