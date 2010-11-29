; PRINT_STR_FREE is like PRINT_STR except
; it frees the memory after the process
;

#include once <alloc.asm>
#include once <printstr.asm>

;;PRINT_STR_FREE:
__PRINTSTR_FREE:
    push hl
    call PRINT_STR
    pop hl
    jp MEM_FREE

