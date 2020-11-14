; Calls PRINT_EOL and then COPY_ATTR, so saves
; 3 bytes

#include once <print.asm>
#include once <copy_attr.asm>

PRINT_EOL_ATTR:
	call PRINT_EOL
	jp COPY_ATTR
