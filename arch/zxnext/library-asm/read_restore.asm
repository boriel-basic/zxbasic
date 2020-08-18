;; This implements READ & RESTORE functions
;; Reads a new element from the DATA Address code
;; Updates the DATA_ADDR read ptr for the next read

;; Data codification is 1 byte for type followed by data bytes
;; Byte type is encoded as follows

;; 00: End of data
;; 01: String
;; 02: Byte
;; 03: Ubyte
;; 04: Integer
;; 05: UInteger
;; 06: Long
;; 07: ULong
;; 08: Fixed
;; 09: Float

;; bit7 is set for a parameter-less function
;; In that case, the next two bytes are the ptr of the function to jump

#include once <error.asm>
#include once <loadstr.asm>
#include once <iload32.asm>
#include once <iloadf.asm>
#include once <ftof16reg.asm>
#include once <f16tofreg.asm>
#include once <free.asm>

#define _str 1
#define _i8  2
#define _u8  3
#define _i16 4
#define _u16 5
#define _i32 6
#define _u32 7
#define _f16 8
#define _flt 9


;; Updates restore point to the given HL mem. address
__RESTORE:
    PROC
    LOCAL __DATA_ADDR

    ld (__DATA_ADDR), hl
    ret

;; Reads a value from the DATA mem area and updates __DATA_ADDR ptr to the
;; next item. On Out Of Data, restarts
;;
__READ:
    LOCAL read_restart, cont, cont2, table, no_func
    LOCAL dynamic_cast, dynamic_cast2, dynamic_cast3, dynamic_cast4
    LOCAL _decode_table, coerce_to_int, coerce_to_int2, promote_to_i16
    LOCAL _from_i8, _from_u8
    LOCAL _from_i16, _from_u16
    LOCAL _from_i32, _from_u32
    LOCAL _from_fixed, __data_error

    push af  ; type of data to read
    ld hl, (__DATA_ADDR)
read_restart:
    ld a, (hl)
    or a   ; 0 => OUT of data
    jr nz, cont
    ;; Signals out of data

    ld hl, __DATA__0
    ld (__DATA_ADDR), hl
    jr read_restart  ; Start again
cont:
    and 0x80
    ld a, (hl)
    push af
    jp z, no_func    ;; Loads data directly, not a function
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld (__DATA_ADDR), hl  ;; Store address of next DATA
    ex de, hl
cont2:
    ld de, dynamic_cast
    push de  ; ret address
    jp (hl)  ; "call (hl)"

    ;; Now tries to convert the given result to the expected type or raise an error
dynamic_cast:
    exx
    ex af, af'
    pop af   ; type READ
    and 0x7F ; clear bit 7
    pop hl   ; type requested by USER (type of the READ variable)
    ld c, h  ; save requested type (save it in register C)
    cp h
    exx
    jr nz, dynamic_cast2  ; Types are identical?
    ;; yes, they are
    ex af, af'
    ret

dynamic_cast2:
    cp _str             ; Requested a number, but read a string?
    jr nz, dynamic_cast3
    call __MEM_FREE     ; Frees str from memory
    jr __data_error

dynamic_cast3:
    exx
    ld b, a     ; Read type
    ld a, c     ; Requested type
    cp _str
    jr z, __data_error
    cp b
    jr c, dynamic_cast4
    ;; here the user expected type is "larger" than the read one
    ld a, b
    sub _i8
    add a, a
    ld l, a
    ld h, 0
    ld de, _decode_table
    add hl, de
    ld e, (hl)
    inc hl
    ld h, (hl)
    ld l, e
    push hl
    ld a, c     ; Requested type
    exx
    ret

__data_error:
    ;; When a data is read, but cannot be converted to the requested type
    ;; that is, the user asked for a string and we read a number or vice versa
    ld a, ERROR_InvalidArg
    call __STOP  ; The user expected a string, but read a number
    xor a
    ld h, a
    ld l, a
    ld e, a
    ld d, a
    ld b, a
    ld c, a
    ret

_decode_table:
    dw _from_i8
    dw _from_u8
    dw _from_i16
    dw _from_u16
    dw _from_i32
    dw _from_u32
    dw _from_fixed

_from_i8:
    cp _i16
    jr nc, promote_to_i16
    ex af, af'
    ret     ;; Was from Byte to Ubyte

promote_to_i16:
    ex af, af'
    ld l, a
    rla
    sbc a, a
    ld h, a     ; copy sgn to h
    ex af, af'
    jr _before_from_i16

_from_u8:
    ex af, af'
    ld l, a
    ld h, 0
    ex af, af'
    ;; Promoted to i16

_before_from_i16:
_from_i16:
    cp _i32
    ret c  ;; from i16 to u16
    ;; Promote i16 to i32
    ex af, af'
    ld a, h
    rla
    sbc a, a
    ld e, a
    ld d, a
    ex af, af'
_from_i32:
    cp _u32
    ret z ;; From i32 to u32
    ret c ;; From u16 to i32
    cp _flt
    jp z, __I32TOFREG
_from_u32:
    cp _flt
    jp z, __U32TOFREG
    ex de, hl
    ld hl, 0
    cp _f16
    ret z
_from_fixed:  ;; From fixed to float
    jp __F16TOFREG
_from_u16:
    ld de, 0    ; HL 0x0000 => 32 bits
    jp _from_i32

dynamic_cast4:
    ;; The user type is "shorter" than the read one
    cp _f16 ;; required type
    jr c, before_to_int  ;; required < fixed (f16)
    ex af, af'
    exx     ;; Ok, we must convert from float to f16
    jp __FTOF16REG

before_to_int:
    ld a, b ;; read type
    cp _f16 ;;
    jr nz, coerce_to_int  ;; From float to int
    ld a, c ;; user type
    exx
    ;; f16 to Long
    ex de, hl
    ld a, h
    rla
    sbc a, a
    ld d, a
    ld e, a
    exx
    jr coerce_to_int2
coerce_to_int:
    exx
    ex af, af'
    call __FTOU32REG
    ex af, af'   ; a contains user type
    exx
coerce_to_int2:  ; At this point we have an u/integer in hl
    exx
    cp _i16
    ret nc       ; Already done. Return the result
    ld a, l      ; Truncate to byte
    ret

no_func:
    exx
    ld de, dynamic_cast
    push de ; Ret address
    dec a        ; 0 => string; 1, 2 => byte; 3, 4 => integer; 5, 6 => long, 7 => fixed; 8 => float
    ld h, 0
    add a, a
    ld l, a
    ld de, table
    add hl, de
    ld e, (hl)
    inc hl
    ld h, (hl)
    ld l, e
    push hl ; address to jump to
    exx
    inc hl
    ret     ; jp (sp)  => jump to table[a - 1]

table:
    LOCAL __01_decode_string
    LOCAL __02_decode_byte
    LOCAL __03_decode_ubyte
    LOCAL __04_decode_integer
    LOCAL __05_decode_uinteger
    LOCAL __06_decode_long
    LOCAL __07_decode_ulong
    LOCAL __08_decode_fixed
    LOCAL __09_decode_float

    ;; 1 -> Decode string
    ;; 2, 3 -> Decode Byte, UByte
    ;; 4, 5 -> Decode Integer, UInteger
    ;; 6, 7 -> Decode Long, ULong
    ;; 8 -> Decode Fixed
    ;; 9 -> Decode Float
    dw __01_decode_string
    dw __02_decode_byte
    dw __03_decode_ubyte
    dw __04_decode_integer
    dw __05_decode_uinteger
    dw __06_decode_long
    dw __07_decode_ulong
    dw __08_decode_fixed
    dw __09_decode_float

__01_decode_string:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld (__DATA_ADDR), hl  ;; Store address of next DATA
    ex de, hl
    jp __LOADSTR
    
__02_decode_byte:
__03_decode_ubyte:
    ld a, (hl)
    inc hl
    ld (__DATA_ADDR), hl
    ret
        
__04_decode_integer:
__05_decode_uinteger:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld (__DATA_ADDR), hl
    ex de, hl
    ret
    
__06_decode_long:
__07_decode_ulong:
__08_decode_fixed:
    ld b, h
    ld c, l
    inc bc
    inc bc
    inc bc
    inc bc
    ld (__DATA_ADDR), bc
    jp __ILOAD32

__09_decode_float:
    call __LOADF
    inc hl
    ld (__DATA_ADDR), hl
    ld h, a  ; returns A in H; sets A free
    ret

__DATA_ADDR:  ;; Stores current DATA ptr
    dw __DATA__0
    ENDP

#undef _str
#undef _i8
#undef _u8
#undef _i16
#undef _u16
#undef _i32
#undef _u32
#undef _f16
#undef _flt
