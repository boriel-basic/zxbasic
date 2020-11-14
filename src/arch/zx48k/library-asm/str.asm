; The STR$( ) BASIC function implementation

; Given a FP number in C ED LH
; Returns a pointer (in HL) to the memory heap
; containing the FP number string representation

#include once <alloc.asm>
#include once <stackf.asm>
#include once <const.asm>

__STR:

__STR_FAST:

	PROC
	LOCAL __STR_END
	LOCAL RECLAIM2
	LOCAL STK_END

	ld hl, (STK_END)
	push hl; Stores STK_END
	ld hl, (ATTR_T)	; Saves ATTR_T since it's changed by STR$ due to a ROM BUG
	push hl

    call __FPSTACK_PUSH ; Push number into stack
	rst 28h		; # Rom Calculator
	defb 2Eh	; # STR$(x)
	defb 38h	; # END CALC
	call __FPSTACK_POP ; Recovers string parameters to A ED CB (Only ED LH are important)

	pop hl
	ld (ATTR_T), hl	; Restores ATTR_T
	pop hl
	ld (STK_END), hl	; Balance STK_END to avoid STR$ bug

	push bc
	push de

	inc bc
	inc bc
	call __MEM_ALLOC ; HL Points to new block

	pop de
	pop bc

	push hl
	ld a, h
	or l
	jr z, __STR_END  ; Return if NO MEMORY (NULL)

	push bc
	push de
	ld (hl), c	
	inc hl
	ld (hl), b
	inc hl		; Copies length

	ex de, hl	; HL = start of original string
	ldir		; Copies string content

	pop de		; Original (ROM-CALC) string
	pop bc		; Original Length
	
__STR_END:
	ex de, hl
	inc bc

	call RECLAIM2 ; Frees TMP Memory
	pop hl		  ; String result

	ret

RECLAIM2 EQU 19E8h
STK_END EQU 5C65h

	ENDP

