; Like USR_STR but frees the string from memory 
; before returning

#include once <usr_str.asm>
#include once <alloc.asm>

USR_STR_FREE:
	push hl
	call USR_STR
	ex (sp), hl
	call __MEM_FREE
	pop hl
	ret

