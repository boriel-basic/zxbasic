;; -----------------------------------------------------------------------
;; ZX Basic System Vars
;; Some of them will be mapped over Sinclair ROM ones for compatibility
;; -----------------------------------------------------------------------

push namespace core

SCREEN_ADDR:        DW 16384  ; Screen address (can be pointed to other place to use a screen buffer)
SCREEN_ATTR_ADDR:   DW 22528  ; Screen attribute address (ditto.)

; These are mapped onto ZX Spectrum ROM VARS

CHARS               EQU 23606  ; Pointer to ROM/RAM Charset
TV_FLAG             EQU 23612  ; TV Flags
UDG                 EQU 23675  ; Pointer to UDG Charset
COORDS              EQU 23677  ; Last PLOT coordinates
FLAGS2              EQU 23681  ;
ECHO_E              EQU 23682  ;
DFCC                EQU 23684  ; Next screen addr for PRINT
DFCCL               EQU 23686  ; Next screen attr for PRINT
S_POSN              EQU 23688
ATTR_P              EQU 23693  ; Current Permanent ATTRS set with INK, PAPER, etc commands
ATTR_T              EQU 23695  ; temporary ATTRIBUTES
P_FLAG              EQU 23697  ;
MEM0                EQU 23698  ; Temporary memory buffer used by ROM chars

SCR_COLS            EQU 33     ; Screen with in columns + 1
SCR_ROWS            EQU 24     ; Screen height in rows
SCR_SIZE            EQU (SCR_ROWS << 8) + SCR_COLS
pop namespace
