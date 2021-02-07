
ld a, 1
ld hl, namespace.AA
ld (hl), a

ld a, namespace.AA

BB EQU .namespace.AA

namespace .namespace
AA:
    defb 0


