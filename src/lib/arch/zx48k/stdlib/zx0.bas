' -----------------------------------------------------------------------------
' BORIEL LIBRARY FOR ZX0 DECOMPRESSORS
'
' USAGE:
'
' 1. Include this library in your program:
'    #include <zx0.bas>
'
' 2. Choose a ZX0 decompressor to use in your program, for instance:
'    dzx0Turbo(51200, 16384)
'
' 3. Compile your program:
'    zxb.exe -T -B prog.bas
'
' Original version and further information is available at
' https://github.com/einar-saukas/ZX0
'
' Copyleft (k) Einar Saukas
' -----------------------------------------------------------------------------

#ifndef __LIBRARY_ZX0__
#define __LIBRARY_ZX0__
#pragma push(case_insensitive)
#pragma case_insensitive = true


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed using ZX0. This is the smallest version of the ZX0 decompressor.
'
' Parameters:
'     src: source address (compressed data)
'     dst: destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0Standard(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & Urusergi
; "Standard" version (68 bytes only)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_standard:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0s_literals:
        call    dzx0s_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0s_new_offset
        call    dzx0s_elias             ; obtain length
dzx0s_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0s_literals
dzx0s_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0s_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0s_elias_backtrack
        inc     bc
        jr      dzx0s_copy
dzx0s_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0s_elias_loop:
        add     a, a
        jr      nz, dzx0s_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0s_elias_skip:
        ret     c
dzx0s_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0s_elias_loop
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed backwards using ZX0. This is the smallest version of the ZX0
' decompressor.
'
' Parameters:
'     src: last source address (compressed data)
'     dst: last destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0StandardBack(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Standard" version (69 bytes only) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_standard_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0sb_literals:
        call    dzx0sb_elias            ; obtain length
        lddr                            ; copy literals
        inc     c
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0sb_new_offset
        call    dzx0sb_elias            ; obtain length
dzx0sb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0sb_literals
dzx0sb_new_offset:
        inc     sp                      ; discard last offset
        inc     sp
        call    dzx0sb_elias            ; obtain offset MSB
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    c, dzx0sb_elias_backtrack
        inc     bc
        jr      dzx0sb_copy
dzx0sb_elias_backtrack:
        add     a, a
        rl      c
        rl      b
dzx0sb_elias:
        add     a, a                    ; inverted interlaced Elias gamma coding
        jr      nz, dzx0sb_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0sb_elias_skip:
        jr      c, dzx0sb_elias_backtrack
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed using ZX0. This is the intermediate version of the ZX0
' decompressor, providing the best balance between speed and size.
'
' Parameters:
'     src: source address (compressed data)
'     dst: destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0Turbo(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & introspec
; "Turbo" version (126 bytes, 21% faster)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_turbo:
        ld      bc, $ffff               ; preserve default offset 1
        ld      (dzx0t_last_offset+1), bc
        inc     bc
        ld      a, $80
        jr      dzx0t_literals
dzx0t_new_offset:
        ld      c, $fe                  ; prepare negative offset
        add     a, a
        jp      nz, dzx0t_new_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_new_offset_skip:
        call    nc, dzx0t_elias         ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0t_last_offset+1), bc ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0t_elias
        inc     bc
dzx0t_copy:
        push    hl                      ; preserve source
dzx0t_last_offset:
        ld      hl, 0                   ; restore offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0t_new_offset
dzx0t_literals:
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0t_literals_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_literals_skip:
        call    nc, dzx0t_elias
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0t_new_offset
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0t_last_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_last_offset_skip:
        call    nc, dzx0t_elias
        jp      dzx0t_copy
dzx0t_elias:
        add     a, a                    ; interlaced Elias gamma coding
        rl      c
        add     a, a
        jr      nc, dzx0t_elias
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
dzx0t_elias_loop:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jr      nc, dzx0t_elias_loop
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        jr      nc, dzx0t_elias_loop
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed backwards using ZX0. This is the intermediate version of the ZX0
' decompressor, providing the best balance between speed and size.
'
' Parameters:
'     src: last source address (compressed data)
'     dst: last destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0TurboBack(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & introspec
; "Turbo" version (126 bytes, 21% faster) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_turbo_back:
        ld      bc, 1                   ; preserve default offset 1
        ld      (dzx0tb_last_offset+1), bc
        ld      a, $80
        jr      dzx0tb_literals
dzx0tb_new_offset:
        add     a, a                    ; obtain offset MSB
        call    c, dzx0tb_elias
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        ld      (dzx0tb_last_offset+1), bc ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    c, dzx0tb_elias_loop
        inc     bc
dzx0tb_copy:
        push    hl                      ; preserve source
dzx0tb_last_offset:
        ld      hl, 0                   ; restore offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0tb_new_offset
dzx0tb_literals:
        add     a, a                    ; obtain length
        call    c, dzx0tb_elias
        lddr                            ; copy literals
        inc     c
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0tb_new_offset
        add     a, a                    ; obtain length
        call    c, dzx0tb_elias
        jp      dzx0tb_copy
dzx0tb_elias_loop:
        add     a, a
        rl      c
        add     a, a
        ret     nc
dzx0tb_elias:
        jp      nz, dzx0tb_elias_loop   ; inverted interlaced Elias gamma coding
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
dzx0tb_elias_reload:
        add     a, a
        rl      c
        rl      b
        add     a, a
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        jr      c, dzx0tb_elias_reload
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed using ZX0. This is the fastest version of the ZX0 decompressor.
'
' Parameters:
'     src: source address (compressed data)
'     dst: destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0Mega(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Mega" version (673 bytes, 28% faster)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_mega:
        ld      bc, $ffff               ; preserve default offset 1
        ld      (dzx0m_last_offset+1), bc
        inc     bc
        jr      dzx0m_literals0

dzx0m_new_offset6:
        ld      c, $fe                  ; prepare negative offset
        add     a, a                    ; obtain offset MSB
        jp      c, dzx0m_new_offset5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset1
dzx0m_elias_offset1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      nc, dzx0m_elias_offset7
dzx0m_new_offset7:
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0m_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      c, dzx0m_length7        ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length3
dzx0m_elias_length3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_length1
dzx0m_length1:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        inc     c
        ldi                             ; copy one more from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0m_new_offset0
dzx0m_literals0:
        inc     c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a                    ; obtain length
        jp      c, dzx0m_literals7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals3
dzx0m_elias_literals3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_literals1
dzx0m_literals1:
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0m_new_offset0
        inc     c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a                    ; obtain length
        jp      c, dzx0m_reuse7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse3
dzx0m_elias_reuse3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_reuse1
dzx0m_reuse1:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0m_literals0

dzx0m_new_offset0:
        ld      c, $fe                  ; prepare negative offset
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a                    ; obtain offset MSB
        jp      c, dzx0m_new_offset7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset3
dzx0m_elias_offset3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_offset1
dzx0m_new_offset1:
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0m_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      c, dzx0m_length1        ; obtain length
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_length7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length5
dzx0m_elias_length5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_length3
dzx0m_length3:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        inc     c
        ldi                             ; copy one more from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0m_new_offset2
dzx0m_literals2:
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_literals1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_literals7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals5
dzx0m_elias_literals5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_literals3
dzx0m_literals3:
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0m_new_offset2
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_reuse1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_reuse7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse5
dzx0m_elias_reuse5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_reuse3
dzx0m_reuse3:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0m_literals2

dzx0m_new_offset2:
        ld      c, $fe                  ; prepare negative offset
        add     a, a                    ; obtain offset MSB
        jp      c, dzx0m_new_offset1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_new_offset7
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset5
dzx0m_elias_offset5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_offset3
dzx0m_new_offset3:
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0m_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      c, dzx0m_length3        ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_length7
dzx0m_elias_length7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_length5
dzx0m_length5:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        inc     c
        ldi                             ; copy one more from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0m_new_offset4
dzx0m_literals4:
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_literals3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_literals7
dzx0m_elias_literals7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_literals5
dzx0m_literals5:
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0m_new_offset4
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_reuse3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_reuse7
dzx0m_elias_reuse7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_reuse5
dzx0m_reuse5:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0m_literals4

dzx0m_new_offset4:
        ld      c, $fe                  ; prepare negative offset
        add     a, a                    ; obtain offset MSB
        jp      c, dzx0m_new_offset3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_new_offset1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      c, dzx0m_new_offset7
dzx0m_elias_offset7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      nc, dzx0m_elias_offset5
dzx0m_new_offset5:
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0m_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      c, dzx0m_length5        ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_length1
dzx0m_elias_length1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      nc, dzx0m_elias_length7
dzx0m_length7:
        push    hl                      ; preserve source
        ld      hl, (dzx0m_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        inc     c
        ldi                             ; copy one more from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jp      c, dzx0m_new_offset6
dzx0m_literals6:
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_literals5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_literals1
dzx0m_elias_literals1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      nc, dzx0m_elias_literals7
dzx0m_literals7:
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jp      c, dzx0m_new_offset6
        inc     c
        add     a, a                    ; obtain length
        jp      c, dzx0m_reuse5
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse3
        add     a, a
        rl      c
        add     a, a
        jp      c, dzx0m_reuse1
dzx0m_elias_reuse1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        add     a, a
        jp      nc, dzx0m_elias_reuse7
dzx0m_reuse7:
        push    hl                      ; preserve source
dzx0m_last_offset:
        ld      hl, 0
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0m_literals6

        jp      dzx0m_new_offset6
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed backwards using ZX0. This is the fastest version of the ZX0
' decompressor.
'
' Parameters:
'     src: last source address (compressed data)
'     dst: last destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0MegaBack(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & introspec
; "Mega" version (676 bytes, 28% faster) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_mega_back:
        ld      bc, 1                   ; preserve default offset 1
        ld      (dzx0mb_last_offset+1), bc
        jr      dzx0mb_literals0

dzx0mb_new_offset6:
        add     a, a                    ; obtain offset MSB
        jp      nc, dzx0mb_new_offset5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset1
dzx0mb_elias_offset1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      c, dzx0mb_elias_offset7
dzx0mb_new_offset7:
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        ld      (dzx0mb_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      nc, dzx0mb_length7      ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length3
dzx0mb_elias_length3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_length1
dzx0mb_length1:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        ldd                             ; copy one more from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0mb_new_offset0
dzx0mb_literals0:
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_literals7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals3
dzx0mb_elias_literals3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_literals1
dzx0mb_literals1:
        lddr                            ; copy literals
        inc     c        
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0mb_new_offset0
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_reuse7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse3
dzx0mb_elias_reuse3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_reuse1
dzx0mb_reuse1:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0mb_literals0

dzx0mb_new_offset0:
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a                    ; obtain offset MSB
        jp      nc, dzx0mb_new_offset7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset3
dzx0mb_elias_offset3:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_offset1
dzx0mb_new_offset1:
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        ld      (dzx0mb_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      nc, dzx0mb_length1      ; obtain length
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_length7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length5
dzx0mb_elias_length5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_length3
dzx0mb_length3:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        ldd                             ; copy one more from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0mb_new_offset2
dzx0mb_literals2:
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_literals1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_literals7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals5
dzx0mb_elias_literals5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_literals3
dzx0mb_literals3:
        lddr                            ; copy literals
        inc     c        
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0mb_new_offset2
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_reuse1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_reuse7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse5
dzx0mb_elias_reuse5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_reuse3
dzx0mb_reuse3:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0mb_literals2

dzx0mb_new_offset2:
        add     a, a                    ; obtain offset MSB
        jp      nc, dzx0mb_new_offset1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_new_offset7
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset5
dzx0mb_elias_offset5:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_offset3
dzx0mb_new_offset3:
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        ld      (dzx0mb_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      nc, dzx0mb_length3      ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_length7
dzx0mb_elias_length7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_length5
dzx0mb_length5:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        ldd                             ; copy one more from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0mb_new_offset4
dzx0mb_literals4:
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_literals3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_literals7
dzx0mb_elias_literals7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_literals5
dzx0mb_literals5:
        lddr                            ; copy literals
        inc     c        
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0mb_new_offset4
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_reuse3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_reuse7
dzx0mb_elias_reuse7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_reuse5
dzx0mb_reuse5:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0mb_literals4

dzx0mb_new_offset4:
        add     a, a                    ; obtain offset MSB
        jp      nc, dzx0mb_new_offset3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_new_offset1
        add     a, a
        rl      c
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      nc, dzx0mb_new_offset7
dzx0mb_elias_offset7:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jp      c, dzx0mb_elias_offset5
dzx0mb_new_offset5:
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        ld      (dzx0mb_last_offset+1), bc ; preserve new offset
        ld      bc, 1
        jp      nc, dzx0mb_length5      ; obtain length
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_length1
dzx0mb_elias_length1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      c, dzx0mb_elias_length7
dzx0mb_length7:
        push    hl                      ; preserve source
        ld      hl, (dzx0mb_last_offset+1)
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        ldd                             ; copy one more from offset
        inc     c        
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jp      c, dzx0mb_new_offset6
dzx0mb_literals6:
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_literals5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_literals1
dzx0mb_elias_literals1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      c, dzx0mb_elias_literals7
dzx0mb_literals7:
        lddr                            ; copy literals
        inc     c        
        add     a, a                    ; copy from last offset or new offset?
        jp      c, dzx0mb_new_offset6
        add     a, a                    ; obtain length
        jp      nc, dzx0mb_reuse5
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse3
        add     a, a
        rl      c
        add     a, a
        jp      nc, dzx0mb_reuse1
dzx0mb_elias_reuse1:
        add     a, a
        rl      c
        rl      b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        add     a, a
        jp      c, dzx0mb_elias_reuse7
dzx0mb_reuse7:
        push    hl                      ; preserve source
dzx0mb_last_offset:
        ld      hl, 0
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        inc     c
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0mb_literals6

        jp      dzx0mb_new_offset6
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed using ZX0. This is the smallest version of the integrated RCS+ZX0
' decompressor.
'
' IMPORTANT: Data decompressed directly to the ZX-Spectrum screen must be both
' RCS encoded and ZX0 compressed, everything else must be ZX0 compressed only.
'
' Parameters:
'     src: source address (compressed data)
'     dst: destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0SmartRCS(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; "Smart" integrated RCS+ZX0 decoder by Einar Saukas (112 bytes)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_smartrcs:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0r_literals:
        call    dzx0r_elias             ; obtain length
dzx0r_literals_loop:
        call    dzx0r_copy_byte         ; copy literals
        jp      pe, dzx0r_literals_loop
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0r_new_offset
        call    dzx0r_elias             ; obtain length
dzx0r_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
dzx0r_copy_loop:
        push    hl                      ; copy from offset
        ex      de, hl
        call    dzx0r_convert
        ex      de, hl
        call    dzx0r_copy_byte
        pop     hl
        inc     hl
        jp      pe, dzx0r_copy_loop
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0r_literals
dzx0r_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0r_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0r_elias_backtrack
        inc     bc
        jr      dzx0r_copy
dzx0r_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0r_elias_loop:
        add     a, a
        jr      nz, dzx0r_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0r_elias_skip:
        ret     c
dzx0r_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0r_elias_loop
dzx0r_copy_byte:
        push    de                      ; preserve destination
        call    dzx0r_convert           ; convert destination
        ldi                             ; copy byte
        pop     de                      ; restore destination
        inc     de                      ; update destination
        ret
; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
dzx0r_convert:
        ex      af, af'
        ld      a, d                    ; A = 010RRccc
        cp      $58
        jr      nc, dzx0r_skip
        xor     e
        and     $f8
        xor     e                       ; A = 010RRppp
        push    af
        xor     d
        xor     e                       ; A = ccrrrccc
        rlca
        rlca                            ; A = rrrccccc
        pop     de                      ; D = 010RRppp
        ld      e, a                    ; E = rrrccccc
dzx0r_skip:
        ex      af, af'
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed backwards using ZX0. This is the smallest version of the
' integrated RCS+ZX0 decompressor.
'
' IMPORTANT: Data decompressed directly to the ZX-Spectrum screen must be both
' RCS encoded and ZX0 compressed, everything else must be ZX0 compressed only.
'
' Parameters:
'     src: last source address (compressed data)
'     dst: last destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0SmartRCSBack(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; "Smart" integrated RCS+ZX0 decoder by Einar Saukas (113 bytes) - BACKWARDS
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_smartrcs_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0rb_literals:
        call    dzx0rb_elias            ; obtain length
dzx0rb_literals_loop:
        call    dzx0rb_copy_byte        ; copy literals
        jp      pe, dzx0rb_literals_loop
        inc     c
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0rb_new_offset
        call    dzx0rb_elias            ; obtain length
dzx0rb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
dzx0rb_copy_loop:
        push    hl                      ; copy from offset
        ex      de, hl
        call    dzx0rb_convert
        ex      de, hl
        call    dzx0rb_copy_byte
        pop     hl
        dec     hl
        jp      pe, dzx0rb_copy_loop
        inc     c
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0rb_literals
dzx0rb_new_offset:
        inc     sp                      ; discard last offset
        inc     sp
        call    dzx0rb_elias            ; obtain offset MSB
        dec     b
        ret     z                       ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    c, dzx0rb_elias_backtrack
        inc     bc
        jr      dzx0rb_copy
dzx0rb_elias_backtrack:
        add     a, a
        rl      c
        rl      b
dzx0rb_elias:
        add     a, a                    ; inverted interlaced Elias gamma coding
        jr      nz, dzx0rb_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0rb_elias_skip:
        jr      c, dzx0rb_elias_backtrack
        ret
dzx0rb_copy_byte:
        push    de                      ; preserve destination
        call    dzx0rb_convert          ; convert destination
        ldd                             ; copy byte
        pop     de                      ; restore destination
        dec     de                      ; update destination
        ret
; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
dzx0rb_convert:
        ex      af, af'
        ld      a, d                    ; A = 010RRccc
        cp      $58
        jr      nc, dzx0rb_skip
        xor     e
        and     $f8
        xor     e                       ; A = 010RRppp
        push    af
        xor     d
        xor     e                       ; A = ccrrrccc
        rlca
        rlca                            ; A = rrrccccc
        pop     de                      ; D = 010RRppp
        ld      e, a                    ; E = rrrccccc
dzx0rb_skip:
        ex      af, af'
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


' -----------------------------------------------------------------------------
' Decompress (from source to destination address) data that was previously
' compressed using ZX0. This is the fastest version of the integrated RCS+ZX0
' decompressor.
'
' IMPORTANT: Data decompressed directly to the ZX-Spectrum screen must be both
' RCS encoded and ZX0 compressed, everything else must be ZX0 compressed only.
'
' Parameters:
'     src: source address (compressed data)
'     dst: destination address (decompressing)
' -----------------------------------------------------------------------------
sub FASTCALL dzx0AgileRCS(src as UINTEGER, dst as UINTEGER)
    asm
        pop bc          ; RET address
        pop de          ; DE=dst
        push bc         ; restore RET address
; -----------------------------------------------------------------------------
; "Agile" integrated RCS+ZX0 decoder by Einar Saukas (187 bytes)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx0_agilercs:
        ld      bc, $ffff               ; preserve default offset 1
        ld      (dzx0a_last_offset+1), bc
        inc     bc
        ld      a, $80
        jr      dzx0a_literals
dzx0a_new_offset:
        ld      c, $fe                  ; prepare negative offset
        add     a, a
        jp      nz, dzx0a_new_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0a_new_offset_skip:
        call    nc, dzx0a_elias         ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0a_last_offset+1), bc ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0a_elias
        inc     bc
dzx0a_copy:
        push    hl                      ; preserve source
dzx0a_last_offset:
        ld      hl, 0                   ; restore offset
        add     hl, de                  ; calculate destination - offset
        ex      af, af'
dzx0a_copy_loop:
        ld      a, h                    ; copy from offset
        cp      $58
        jr      nc, dzx0a_copy_ldir
        push    hl
        ex      de, hl
        call    dzx0a_convert
        ex      de, hl
        push    de
        ld      a, d
        cp      $58
        call    c, dzx0a_convert
        ldi
        pop     de
        inc     de
        pop     hl
        inc     hl
        jp      pe, dzx0a_copy_loop
        db      $ea                     ; skip next instruction
dzx0a_copy_ldir:
        ldir
        ex      af, af'
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0a_new_offset
dzx0a_literals:
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0a_literals_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0a_literals_skip:
        call    nc, dzx0a_elias
        ex      af, af'
dzx0a_literals_loop:
        ld      a, d                    ; copy literals
        cp      $58
        jr      nc, dzx0a_literals_ldir
        push    de
        call    dzx0a_convert
        ldi
        pop     de
        inc     de
        jp      pe, dzx0a_literals_loop
        db      $ea                     ; skip next instruction
dzx0a_literals_ldir:
        ldir
        ex      af, af'
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0a_new_offset
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0a_last_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0a_last_offset_skip:
        call    nc, dzx0a_elias
        jp      dzx0a_copy
dzx0a_elias:
        add     a, a                    ; interlaced Elias gamma coding
        rl      c
        add     a, a
        jr      nc, dzx0a_elias
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
dzx0a_elias_loop:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jr      nc, dzx0a_elias_loop
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        jr      nc, dzx0a_elias_loop
        ret
; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
dzx0a_convert:                          ; A = 010RRccc
        xor     e
        and     $f8
        xor     e                       ; A = 010RRppp
        push    af
        xor     d
        xor     e                       ; A = ccrrrccc
        rlca
        rlca                            ; A = rrrccccc
        pop     de                      ; D = 010RRppp
        ld      e, a                    ; E = rrrccccc
        ret
; -----------------------------------------------------------------------------
    end asm
end sub


#pragma pop(case_insensitive)
#endif
