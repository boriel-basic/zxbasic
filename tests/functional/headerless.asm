	org 32768
core.__START_PROGRAM:
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core..__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core..__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_a:
	DEFB 02h
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld hl, _a
	inc (hl)
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	ret
	;; --- end of user code ---
	END core.__START_PROGRAM
