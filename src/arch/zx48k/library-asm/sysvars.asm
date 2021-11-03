;; -----------------------------------------------------------------------
;; ZX Basic System Vars
;; Some of them will be mapped over Sinclair ROM ones for compatibility
;; -----------------------------------------------------------------------

push namespace core

SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)

; These are mapped onto ZX Spectrum ROM VARS

CHARS	            EQU 23606  ; Pointer to ROM/RAM Charset
TVFLAGS             EQU 23612  ; TV Flags
UDG	                EQU 23675  ; Pointer to UDG Charset
COORDS              EQU 23677  ; Last PLOT coordinates
FLAGS2	            EQU 23681  ;
ECHO_E              EQU 23682  ;
DFCC                EQU 23684  ; Next screen addr for PRINT
DFCCL               EQU 23686  ; Next screen attr for PRINT
S_POSN              EQU 23688
ATTR_P              EQU 23693  ; Current Permanent ATTRS set with INK, PAPER, etc commands
ATTR_T	            EQU 23695  ; temporary ATTRIBUTES
P_FLAG	            EQU 23697  ;
MEM0                EQU 23698  ; Temporary memory buffer used by ROM chars

;; Screen MAX col (MAXX) and MAX row (MAXY)
MAXX                EQU ECHO_E   ; Max X position + 1
MAXY                EQU MAXX + 1 ; Max Y position + 1

;; Screen current ROW, COL (POSX, POSY) position
POSX                EQU S_POSN     ; Current POS X
POSY                EQU S_POSN + 1 ; Current POS Y

pop namespace
