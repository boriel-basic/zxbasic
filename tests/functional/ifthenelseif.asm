	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core.__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_a:
	DEFB 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
__LABEL__5:
__LABEL__10:
	ld h, 1
	ld a, (_a)
	call core.__LTI8
	or a
	jp z, __LABEL0
	ld hl, _a
	inc (hl)
__LABEL__20:
	jp __LABEL1
__LABEL0:
	xor a
	ld hl, (_a - 1)
	call core.__LTI8
	or a
	jp z, __LABEL3
	xor a
	ld (_a), a
__LABEL__30:
__LABEL3:
__LABEL1:
__LABEL__40:
	ld h, 1
	ld a, (_a)
	call core.__LTI8
	or a
	jp z, __LABEL4
	ld hl, _a
	inc (hl)
__LABEL__50:
	jp __LABEL5
__LABEL4:
	xor a
	ld hl, (_a - 1)
	call core.__LTI8
	or a
	jp z, __LABEL6
	xor a
	ld (_a), a
	jp __LABEL7
__LABEL6:
	ld a, (_a)
	or a
	jp nz, __LABEL9
	ld a, 255
	ld (_a), a
__LABEL__60:
__LABEL9:
__LABEL7:
__LABEL5:
	ld h, 1
	ld a, (_a)
	call core.__LTI8
	or a
	jp z, __LABEL10
	ld hl, _a
	inc (hl)
	jp __LABEL11
__LABEL10:
	xor a
	ld hl, (_a - 1)
	call core.__LTI8
	or a
	jp z, __LABEL13
	xor a
	ld (_a), a
__LABEL13:
__LABEL11:
	ld h, 1
	ld a, (_a)
	call core.__LTI8
	or a
	jp z, __LABEL14
	ld hl, _a
	inc (hl)
	jp __LABEL15
__LABEL14:
	xor a
	ld hl, (_a - 1)
	call core.__LTI8
	or a
	jp z, __LABEL16
	xor a
	ld (_a), a
	jp __LABEL17
__LABEL16:
	ld a, (_a)
	or a
	jp nz, __LABEL19
	ld a, 255
	ld (_a), a
__LABEL19:
__LABEL17:
__LABEL15:
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lei8.asm"
	    push namespace core
__LEI8: ; Signed <= comparison for 8bit int
	    ; A <= H (registers)
	    PROC
	    LOCAL checkParity
	    sub h
	    jr nz, __LTI
	    inc a
	    ret
__LTI8:  ; Test 8 bit values A < H
	    sub h
__LTI:   ; Generic signed comparison
	    jp po, checkParity
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/arch/zx48k/library-asm/lti8.asm"
#line 112 "ifthenelseif.bas"
	END
