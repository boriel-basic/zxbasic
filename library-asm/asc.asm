; Returns the ascii code for the given str
#include once <free.asm>

__ASC:
	PROC
	LOCAL __ASC_END
	
	ex af, af'	; Saves free_mem flag

	ld a, h
	or l
	ret z		; NULL? return

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	ld a, b
	or c
	jr z, __ASC_END		; No length? return

	ld a, (hl)
	
__ASC_END:
	dec hl
	dec hl
	ex af, af'
	or a
	call nz, __MEM_FREE	; Free memory if needed

	ex af, af'	; Recover result

	ret
	ENDP
