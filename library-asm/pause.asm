; The PAUSE statement (Calling the ROM)

__PAUSE:
	ld b, h
    ld c, l
    jp 1F3Dh  ; PAUSE_1
