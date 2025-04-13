	org 32768
.core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld (.core.__CALL_BACK__), sp
	ei
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
_a:
	DEFB 00h
_c:
	DEFB 0FFh
	DEFB 7Fh
	DEFB 00h
	DEFB 00h
_d:
	DEFB 00h
	DEFB 0FEh
	DEFB 0FFh
	DEFB 0FFh
_result:
	DEFB 00, 00
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	ld hl, (_c)
	ld de, (_c + 2)
	ld (_result), hl
	ld hl, (_c)
	ld de, (_c + 2)
	call .core.__SHRL32
	ld (_result), hl
	ld hl, (_c)
	ld de, (_c + 2)
	ld b, 2
.LABEL.__LABEL0:
	call .core.__SHRL32
	djnz .LABEL.__LABEL0
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, (_c)
	ld de, (_c + 2)
	or a
	jr z, .LABEL.__LABEL2
.LABEL.__LABEL1:
	call .core.__SHRL32
	djnz .LABEL.__LABEL1
.LABEL.__LABEL2:
	ld (_result), hl
	ld hl, (_c)
	ld de, (_c + 2)
	ld (_result), hl
	ld hl, (_c)
	ld de, (_c + 2)
	call .core.__SHL32
	ld (_result), hl
	ld hl, (_c)
	ld de, (_c + 2)
	ld b, 2
.LABEL.__LABEL3:
	call .core.__SHL32
	djnz .LABEL.__LABEL3
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, (_c)
	ld de, (_c + 2)
	or a
	jr z, .LABEL.__LABEL5
.LABEL.__LABEL4:
	call .core.__SHL32
	djnz .LABEL.__LABEL4
.LABEL.__LABEL5:
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	call .core.__SHRA32
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	ld b, 2
.LABEL.__LABEL6:
	call .core.__SHRA32
	djnz .LABEL.__LABEL6
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, (_d)
	ld de, (_d + 2)
	or a
	jr z, .LABEL.__LABEL8
.LABEL.__LABEL7:
	call .core.__SHRA32
	djnz .LABEL.__LABEL7
.LABEL.__LABEL8:
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	call .core.__SHL32
	ld (_result), hl
	ld hl, (_d)
	ld de, (_d + 2)
	ld b, 2
.LABEL.__LABEL9:
	call .core.__SHL32
	djnz .LABEL.__LABEL9
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, (_d)
	ld de, (_d + 2)
	or a
	jr z, .LABEL.__LABEL11
.LABEL.__LABEL10:
	call .core.__SHL32
	djnz .LABEL.__LABEL10
.LABEL.__LABEL11:
	ld (_result), hl
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bitwise/shl32.asm"
	    push namespace core
__SHL32: ; Left Logical Shift 32 bits
	    sla l
	    rl h
	    rl e
	    rl d
	    ret
	    pop namespace
#line 117 "arch/zx48k/shl_shr_32bit.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bitwise/shra32.asm"
	    push namespace core
__SHRA32: ; Right Arithmetical Shift 32 bits
	    sra d
	    rr e
	    rr h
	    rr l
	    ret
	    pop namespace
#line 118 "arch/zx48k/shl_shr_32bit.bas"
#line 1 "/zxbasic/src/lib/arch/zx48k/runtime/bitwise/shrl32.asm"
	    push namespace core
__SHRL32: ; Right Logical Shift 32 bits
	    srl d
	    rr e
	    rr h
	    rr l
	    ret
	    pop namespace
#line 119 "arch/zx48k/shl_shr_32bit.bas"
	END
