; CHARSET — Fuente de caracteres 8x8 compatible Spectrum
;
; 96 caracteres × 8 bytes, desde CHR$(32) hasta CHR$(127).
; Fichero externo: specfont.bin (debe estar en el mismo directorio).

    push namespace core

__ZX81SD_CHARSET:
    INCBIN "specfont.bin"

; Area de UDGs (CHR$(144) a CHR$(164), 21 caracteres como en el Spectrum).
; La fuente solo cubre CHR$(32)-CHR$(127) (768 bytes): sin este bloque,
; apuntar UDG a "font+896" caia 128 bytes MAS ALLA del final de la fuente,
; sobre el codigo que tocara despues en el enlazado (los POKE USR CHR$
; de un programa corrompian el runtime). SD81_INIT_SYSVARS la inicializa
; con copias de las letras A-U, igual que la ROM del Spectrum.
__ZX81SD_UDG_AREA:
    defs 21 * 8

    pop namespace
