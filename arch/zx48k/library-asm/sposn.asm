; Printing positioning library.
		PROC
		LOCAL ECHO_E 

__LOAD_S_POSN:		; Loads into DE current ROW, COL print position from S_POSN mem var.
		ld de, (S_POSN)
		ld hl, (MAXX)
		or a
		sbc hl, de
		ex de, hl
		ret
	

__SAVE_S_POSN:		; Saves ROW, COL from DE into S_POSN mem var.
		ld hl, (MAXX)
		or a
		sbc hl, de
		ld (S_POSN), hl ; saves it again
		ret


ECHO_E	EQU 23682
MAXX	EQU ECHO_E   ; Max X position + 1
MAXY	EQU MAXX + 1 ; Max Y position + 1

S_POSN	EQU 23688 
POSX	EQU S_POSN		; Current POS X
POSY	EQU S_POSN + 1	; Current POS Y

		ENDP

