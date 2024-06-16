; Calls PRINT_EOL and then COPY_ATTR, so saves
; 3 bytes

#include once <print.asm>
#include once <copy_attr.asm>

    push namespace core

PRINT_EOL_ATTR:
    call PRINT_EOL
    jp COPY_ATTR

    pop namespace
