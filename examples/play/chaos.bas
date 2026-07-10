rem Chaos
rem (C) 2026 by Ollibony

#include <play.bas>

cls

let x$ = "1 a&&C&&a&&&g&a&&& f&&C&&a&&&f&a&&& g&&D&&b&&&a&b&&& a&&C&&D&&&C&b&g& "
let y$ = "1 f&&C&&a&&&f&g&&& a&&C&&a&&&g&a&&& g&&D&&b&&&a&b&&& g&&b&&D&&&C&b&g& "

let z$ = "O5 V8 5eV7eV6eV5e V8cV7cV6cV5c (V8dV7dV6dV5d) (V8cV7cV6cV5c) (V8dV7dV6dV5d)"

let a$ = x$ + y$
let b$ = z$
let c$ = "V10 1&&& " + x$ + y$

print ink 1; "Channel A"
print a$: print
print ink 1; "Channel B"
print b$: print
print ink 1; "Channel C"
print c$: print

Play a$, b$, c$
