	org 32768
	ld hl, _a
	inc (hl)
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	ret

ZXBASIC_USER_DATA:
_a:
	DEFB 02h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
