	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_temp_wav_add:
	DEFB 00, 00
_temp_ch_len:
	DEFB 00, 00
_temp_wav_len:
	DEFB 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld a, 1
	push af
	call _adjustwavelength
	ld bc, 0
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
_adjustwavelength:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, (_temp_ch_len)
	ld a, (hl)
	ld (_temp_wav_len), a
	ld a, (ix+5)
	or a
	jp nz, .LABEL.__LABEL0
	ld hl, _temp_wav_len
	dec (hl)
	jp .LABEL.__LABEL1
.LABEL.__LABEL0:
	ld hl, _temp_wav_len
	inc (hl)
.LABEL.__LABEL1:
	ld a, (_temp_wav_len)
	ld hl, (_temp_wav_add)
	ld (hl), a
	ld hl, (_temp_ch_len)
	ld (hl), a
_adjustwavelength__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
	;; --- end of user code ---
	END
