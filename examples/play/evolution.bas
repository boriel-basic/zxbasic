rem Evolution
rem (C) 2026 by Ollibony

#include <play.bas>

cls

let z$ = "T160 O3 1e&&Ee&(e&&&)e& 1d&&Dd&(d&&&)d& 1c&&Cc&(c&&&)c& O2 1a&&Aa&(a&&&)a& "
let x$ = "O3 1e&&Ee&(e&&&)e& 1g&&Gg&g&&&d&4d1& 1c&&Cc&(c&&&)c& O2 1a&&Aa&a&&&a&a&a& O5 3g"

let b$ = "O5 ((1gab&&&ab&&e&&&d&) 1abC&&&bC&&e&&&d& 1ega&5&&&) 3e"

let c$ = "O5 9&&&&& 1bCD&&&CD&&b&&&g& 1CDE&&&DE&&C&&&g& 1Cba&5&&& O4 3b"

let a$ = z$ + x$

print ink 1; "Channel A"
print a$: print
print ink 1; "Channel B"
print b$: print
print ink 1; "Channel C"
print c$: print

Play a$, b$, c$
