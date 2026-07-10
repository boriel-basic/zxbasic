# Precautions when writing or porting software for zx81sd

zx81sd makes ZX BASIC generate binaries that "look like" a Spectrum
(the SD81 Booster interface emulates its screen, and much of the
shared stdlib assumes Spectrum conventions), but **there is no
Spectrum ROM anywhere**: no ROM `RST $28`, no routines at fixed
addresses, no Spectrum sysvars at `$5C00+`. Almost every bug in this
port has come from code (official `examples/` or the shared stdlib)
that silently assumes one of these things. Check this list before
porting anything.

## 1. There's never a ROM: watch out for absolute addresses and sysvars

Any `POKE`/`PEEK`/`CALL` to a fixed numeric address (23675, 23658,
$22AC, $0DFE...) is almost certainly a **Spectrum ROM** sysvar or
routine, which doesn't exist in zx81sd: that address lands in free RAM,
or worse, in the middle of the program's own compiled code — executing
or interpreting it as data causes silent corruption, wrong graphics, or
a runaway `HALT`/reset that's very hard to trace back to its cause
(several bugs in this port took whole sessions to diagnose because of
this).

- **Spectrum sysvars → zx81sd sysvars**: the equivalence table is in
  [`../../../lib/arch/zx81sd/runtime/sysvars.asm`](../../../lib/arch/zx81sd/runtime/sysvars.asm)
  (all live at `$8000+`, not `$5C00+`). Examples already solved:
  `UDG` (23675 → `$8002`), `COORDS` (23677/23678 → `$8004`/`$8005`).
  See [BASIC_CHANGES.md](BASIC_CHANGES.md) for the line-by-line detail
  of every case found so far.
- **ROM routines called directly** (`call $22AC` = PIXEL-ADD,
  `call $0DFE` = CL-SC-ALL/scroll, `RST $28` = FP calculator...): if the
  source or a shared library does this, it needs an override in
  `src/lib/arch/zx81sd/` that replaces the call with our own routine,
  keeping the **same register contract** as the ROM one (see below).
  Example already solved: `stdlib/scroll.bas`.
- **Preventive `grep`**: when porting a file from `zx48k/` to
  `zx81sd/`, search for `EQU 0[0-9A-F]` / `call 0x` / suspicious
  4-5-digit literals before signing off on it, not only once something
  actually fails.

## 2. ASM routine register contracts are sacred

Several runtime routines have explicit, non-negotiable register
preservation contracts, because the code that calls them (inherited
from zx48k, not something we can touch) depends on them to the letter.
Examples:

- `PIXEL_ADDR` (`runtime/pixel_addr.asm`): A=191, B=Y, C=X → HL=offset,
  A=X AND 7; **destroys B, preserves D and E**. `draw.asm` stores the
  Bresenham coordinate in D around the call, trusting this literally —
  breaking it (as happened once with an attempt that used D as
  scratch) corrupts every line with a vertical component while leaving
  horizontal ones untouched, which is very misleading to diagnose.
- `GetBankPreservingRegs`/`SetBankPreservingINTs` (MSFS,
  `cb/maskedsprites.bas`): documented contract "preserves D,E,H,L".
  Writing the replacement in plain BASIC instead of hand-written ASM
  breaks this with no warning from the compiler (compiled BASIC code
  uses registers freely internally) — a real bug of this kind made all
  6 test sprites register at the same wrong address. **Note**: the
  MSFS/`maskedsprites.bas` port is still in progress (still not fully
  working) — this specific example is here to illustrate the class of
  bug, not to confirm the library is finished.

**Practical rule**: if you're going to replace an ASM routine that has
a documented register contract (or one that can be inferred from
looking at its callers and what they assume), reimplement it in
hand-written ASM preserving that exact contract. A BASIC function
(`SUB`/`FUNCTION`), however simple it looks, is NOT a valid replacement
unless the contract is "none".

## 3. The keyboard is the ZX81's, not the Spectrum's

The SD81 Booster doesn't have a Spectrum keyboard: it rescans the
ZX81's own physical 40-key keyboard (`runtime/io/keyboard/keyscan.asm`).
Differences that matter when porting/writing code:

- Direct key press: lowercase. `SHIFT+letter`: UPPERCASE of that letter
  — exactly like a real Spectrum, unlike the original ZX81 (where
  `SHIFT+letter` produced a symbol, not an uppercase letter). This
  redefinition is a design decision of this port, see [MAP.md](MAP.md)
  section "New keyboard scheme". As a result, **you can indeed
  scan/compare `INKEY$` against uppercase letters**
  (`IF INKEY$="S"`, meant to be played holding `SHIFT` Spectrum-style)
  with no hardware limitation: just press `SHIFT+S`.
- `SHIFT+"2"` toggles a persistent CAPS LOCK.
- `"."` is a normal key (`.` unshifted, `,` shifted). The original
  ZX81 symbols associated with each key (`:` on Z, `)` on O, etc.) are
  reached with the `"." + key` sequence **only from `INPUT()`** (a
  dead-key handled in `stdlib/input.bas`), not from raw `INKEY$` — there
  is no reliable way to "hold both at once" on this keyboard, so the
  composition is done by pressing `.` first and the second key after.
  Pressing `.` **twice in a row** confirms the first dot as a literal
  and cancels any pending combo: the key that comes after that second
  dot is read as a fresh keypress, with no combination (lets you type
  any key right after a dot without risking forming a symbol by
  accident).

## 4. There are no interrupts: never wait on `HALT`/`EI` to synchronize

The zx81sd runtime always runs with interrupts disabled (`DI`); the
`$0038` vector is only a `DI;HALT` trap, not a real interrupt handler.
Any code (typically inline ASM in an example, not the stdlib) that
does `EI` followed by `HALT` waiting for the Spectrum ROM's 50Hz pulse
**hangs forever** — nothing ever wakes it up.

- **Replacement**: `VSYNC_TICK` (namespace `core`, in
  `runtime/vsync.asm`) polls the SD81 Booster hardware's real VSYNC
  pulse counter through a port. `PAUSE` already uses it internally.
- When calling it from an `ASM ... END ASM` block that isn't already
  inside `push namespace core`, you need the full prefix:
  `call .core.VSYNC_TICK` (omitting the prefix gives
  `Undefined GLOBAL label '.VSYNC_TICK'` — an error already seen more
  than once in this port).
- A counter that used to be incremented only by the background
  interrupt (`FRAMES`/23672 on the Spectrum) needs to be updated by
  hand, calling `VSYNC_TICK` explicitly on every loop iteration that
  still needs to wait, not just once at the start.

## 5. ASM label namespaces and mangling

A BASIC `DIM X` or `SUB`/`FUNCTION X` translates to the ASM label `_X`
(a single leading underscore), **unless** the file wraps its code in
`push namespace core ... pop namespace`, in which case you must
reference it from outside as `.core._X` (variables) or `.core.X`
(functions/routines). Getting this wrong in either direction produces
`Undefined GLOBAL label`. If a file in this port doesn't use
namespacing anywhere else, there's no need to wrap a new `ASM` block in
`push namespace core` just because another file (like `vsync.asm`)
does — just prefix the specific reference.

## 6. The dead-code eliminator can't see calls made from hand-written ASM

The compiler's "is this used?" analysis only counts calls made with
BASIC call syntax (`Foo(x)`). A BASIC `SUB`/`FUNCTION`/variable
referenced **only** from an `ASM ... END ASM` block (e.g. `call _Foo`)
can be eliminated as dead code, producing `Undefined GLOBAL label
'._Foo'` at link time — the symbol never made it into the final
binary. Two ways out:

- If it's pure data (a state byte, for example), declare it as raw ASM
  (`ASM \n _Label: \n DEFB 0 \n END ASM` at file scope), not as `DIM`.
- If it's a function that genuinely needs to be BASIC (because it
  calls other stdlib things), add one real BASIC-level call (even if
  redundant/not strictly needed at that point) somewhere reachable in
  the code, so the usage analysis counts it.

## 7. Debugging methodology without hardware

To diagnose things without burning trial-and-error cycles on the
emulator or real hardware, this port uses direct simulation of the
binary with Python's `z80` package. Two lessons already learned the
hard way (documented in more detail in [MAP.md](MAP.md)):

- Checking the PC periodically every N coarse ticks can give a false
  "stuck" reading if it just happens to always land on the same point
  of a loop; use real breakpoints (compare `m.pc` against the exact
  address, taken from the `.map`) or finer tick chunks.
- The simulator's RAM starts at **zero**, just like a Spectrum's after
  its ROM's RAM test. This hides uninitialized-memory bugs (it gave two
  false "OK" results in a row in the MSFS free-space-bitmap bug). To
  validate code that reads memory it doesn't initialize itself, fill
  all unloaded RAM with `0xFF` before loading the binary, to reproduce
  real hardware/card conditions.
- The simulator **doesn't model the memory mapper** (`OUT` to port
  `$E7` is a no-op): it can validate that the Z80 logic is
  self-consistent, but not that the actual physical page-swapping
  works — that's only confirmed on the emulator (EightyOne) or real
  hardware.
- If a binary fails on EightyOne but the Python simulation runs it
  clean, suspect the emulator first (see the tape-trap bug already
  found and fixed in `Eightyone2/src/ZX81/rompatch.cpp`, in the
  emulator's own repository, not this one) before the runtime — those
  traps don't exist on real hardware.

## 8. Never do `#include once <sysvars.asm>` from your own library

If you need zx81sd's own sysvars (`CHARS`/`UDG`/`ATTR_P`/
`SCREEN_ADDR`/`SCREEN_ATTR_ADDR`...) from a new `stdlib/*.bas` file,
**don't include it yourself with `#include once <sysvars.asm>`** — just
reference the symbols with the `.core.` prefix (see point 5) and trust
that the rest of the runtime already brought it in.

`sysvars.asm` drags in `bootstrap.asm` → `charset.asm`, and the latter
does `INCBIN "specfont.bin"` (the complete font, binary bytes, not
assembly text). If your file turns out to be the **first** one to
include `sysvars.asm` in the whole compiled program (easy to happen: a
`#include <yourlibrary.bas>` at the top of the user's source is
processed before any `CLS`/`PRINT` that comes later in the text), that
`INCBIN` gets emitted **right at the point in the source file where you
put the `#include`**:

- Placed at BASIC level (outside an `ASM ... END ASM` block): the
  BASIC lexer tries to tokenize those binary bytes as if they were
  source text → `error: illegal preprocessor character` on lines that
  have nothing to do with the real problem (misattributed to the start
  of the file).
- Placed inside an `ASM` block (e.g. at the start of a function body):
  the font binary gets emitted literally in the middle of that
  function's compiled code — it compiles without error, but the CPU
  "executes" those font bytes as if they were instructions the moment
  control flow falls there, producing a `HALT` or erratic behavior at
  an address that appears completely unrelated to the bug (found while
  porting `print42.bas`/`print64.bas`, see
  [BASIC_CHANGES.md](BASIC_CHANGES.md)).

Any real program using your library will almost certainly also use
`CLS`/`PRINT` somewhere, and those routines already require
`sysvars.asm` — so leaving out the `#include` in your file is safe in
practice, not a hack.

## See also

- [BASIC_CHANGES.md](BASIC_CHANGES.md) — catalog of source changes
  already needed in official examples, with the general pattern to look
  for in any new example.
- [MAP.md](MAP.md) — full technical log, bug by bug, with the
  investigation traces.
