# BASIC source changes needed to port official examples to zx81sd

This file records, for every official `examples/` sample tried on
zx81sd, whether the BASIC source needed touching (never the original:
always an adapted copy in `examples/sd81/`) or just different compile
flags.

Ground rule: the official zxbasic source **is never modified**. When a
program depends on a Spectrum-specific sysvar or absolute address, an
adapted copy is made next to the original.

---

## 1. `examples/english/comecoquitos.bas` — NO source changes

Compiles as-is. Only needs command-line flags:

```
python -m src.zxbc.zxbc comecoquitos.bas --arch zx81sd --string-base 1 --array-base 1 -o comecocos.bin
```

**Why**: the source uses 1-based string indexing (classic Sinclair
BASIC style, `l$(f)`, slicing). With zxbasic's default 0-based indexing,
the collision comparisons end up shifted by one position — not a bug in
the port, it happens exactly the same on zx48k without those flags.

---

## 2. `examples/english/snake_en.bas` → `examples/sd81/snake_sd81.bas`

One single-line change:

```diff
-73   POKE UINTEGER 23675, @udg(0, 0): REM Sets UDG variable to first element
+73	 POKE UINTEGER $8002, @udg(0, 0): REM zx81sd's UDG sysvar (was 23675 on Spectrum)
```

**Why**: `23675` ($5C7B) is the absolute address of the `UDG` sysvar in
the **Spectrum**'s memory map. On zx81sd the same sysvar lives at
`$8002` (see `SYSVAR_BASE+2` in `src/lib/arch/zx81sd/runtime/sysvars.asm`).
Without the change, the POKE lands in free RAM and the UDGs (the
snake's head and fruit) never activate — the game would run but draw
blank spaces instead of the graphics.

**General pattern**: any example that does `POKE`/`PEEK` on a Spectrum
sysvar address instead of using the higher-level function (here it
would have been enough not to use raw UDG) needs this kind of address
translation. See also flights.bas below.

---

## 3. `examples/flights.bas` → `examples/sd81/flights_sd81.bas`

Three content changes (plus cosmetic trailing-whitespace cleanup with
no functional effect, not listed):

### 3.1 Remove a Spectrum sysvar POKE with no equivalent

```diff
-1 POKE 23658,8: BORDER 1: PAPER 1: INK 7: CLS 
+1 BORDER 1: PAPER 1: INK 7: CLS
```

**Why**: `23658` ($5C6A) is `REPDEL` (key repeat delay) on the
Spectrum — that sysvar doesn't exist on zx81sd, and the POKE would
write to an arbitrary RAM address. Simply removed: the effect
(adjusting keyboard auto-repeat) has no equivalent and isn't needed by
the game.

### 3.2 Translate the COORDS sysvar to its real zx81sd address

```diff
-2295 IF gc<>0 THEN PLOT OVER 1;x1,168+16-y1: DRAW OVER 1;x2-PEEK 23677,168+16-y2-PEEK 23678: END IF
+2295 IF gc<>0 THEN PLOT OVER 1;x1,168+16-y1: DRAW OVER 1;x2-PEEK $8004,168+16-y2-PEEK $8005: END IF
```
(and three more identical occurrences on lines 2370, 2378 and 2445)

**Why**: `23677`/`23678` ($5C7D/$5C7E) are the Spectrum's `COORDS`
sysvar (last `PLOT` coordinate). On zx81sd it lives at `$8004`/`$8005`
(`COORDS EQU SYSVAR_BASE+$04` in `sysvars.asm`). Without the
translation, the `PEEK`s read the compiled program's own RAM instead
of the actual coordinate, and the horizon-line `DRAW` comes out with a
random offset depending on that RAM's contents — this was the first
symptom reported ("the horizon line draws wrong").

### 3.3 Key comparisons to lowercase

```diff
-3010 IF k$="S" THEN LET pow=pow-1: END IF
-3020 IF k$="F" THEN LET pow=pow+1: END IF
-3030 IF k$="Q" THEN LET pt=pt+1: END IF
-3040 IF k$="A" THEN LET pt=pt-1: END IF
-3050 IF k$="O" AND rl>-30 THEN LET rl=rl-1: END IF
-3060 IF k$="P" AND rl<30 THEN LET rl=rl+1: END IF
+3010 IF k$="s" THEN LET pow=pow-1: END IF
+3020 IF k$="f" THEN LET pow=pow+1: END IF
+3030 IF k$="q" THEN LET pt=pt+1: END IF
+3040 IF k$="a" THEN LET pt=pt-1: END IF
+3050 IF k$="o" AND rl>-30 THEN LET rl=rl-1: END IF
+3060 IF k$="p" AND rl<30 THEN LET rl=rl+1: END IF
```
(and the "Y"/"N" comparisons on lines 6150/6160)

**Why (this change matches the old keyboard scheme — see the "no
longer needed" note below)**: at the time `flights.bas` was ported,
`zx81sd/runtime/io/keyboard/keyscan.asm` (a hand-written rescan of the
**ZX81's own physical keyboard**, since the SD81 Booster has no
Spectrum keyboard) only ever returned lowercase, regardless of
whether `SHIFT` was pressed — `SHIFT+letter` didn't produce the
uppercase of that letter, but one of the ZX81's classic symbols (colon,
quotes, `+`, `-`...). With that scheme there was no physical
combination that reproduced Spectrum-style "CAPS SHIFT+S", and the only
possible adaptation was comparing against the unshifted lowercase.
Same reason, already solved a different way in `comecoquitos.bas`
(there the source already compared in lowercase, "o","p","q","a","y","n"
— its author just happened to type it that way, nothing we had to
touch) and in `snake_sd81.bas` (compares "O"/"o" with `OR`, covering
both cases without needing any change).

**No longer needed (2026-07-04)**: `keyscan.asm` was redesigned so a
direct key press gives lowercase and `SHIFT+letter` gives the
UPPERCASE of that letter (plus `SHIFT+"2"` as a persistent CAPS LOCK,
and the ZX81's classic symbols reachable with `"."+key` from
`INPUT()`). With the current scheme, `INKEY$="S"` would already work
naturally by pressing `SHIFT+S`, exactly like on a Spectrum — the
case change in `flights_sd81.bas` documented above was necessary at the
time but wouldn't be needed if ported today from scratch. Kept here as
a record instead of reverting the already-tested copy. Full detail of
the redesign in [MAP.md](MAP.md), section "New keyboard scheme".

---

## 4. `examples/english/4inarow.bas` — NO source changes

Compiles with default flags:

```
python -m src.zxbc.zxbc 4inarow.bas --arch zx81sd -o row4.bin
```

Its arrays use indices 1..8, which fit in the default 0-based indexing
without any slicing collision (it doesn't do string slicing), and its
key comparisons already use lowercase ("y"/"n" in the prompts). It
exercises the arc code (`DRAW 8,0,PI`) and `CIRCLE` without needing any
patch.

---

## 5. `examples/scroll.bas` — NO source changes

Compiles with default flags:

```
python -m src.zxbc.zxbc scroll.bas --arch zx81sd -o scroll.bin
```

The problem wasn't in the example but in the library: `scroll.bas` had
no zx81sd version — the zx48k one was used as-is, and its 8 subs
(`ScrollRight/Left/Up/Down` + their `*Aligned` variants) call `$22AC`
(the Spectrum ROM's *PIXEL-ADD* routine, which doesn't exist on
zx81sd). `src/lib/arch/zx81sd/stdlib/scroll.bas` was created, identical
except those 8 calls are replaced with `call PIXEL_ADDR` (our own
implementation, same register contract as the ROM — see
[MAP.md](MAP.md)). The example itself needed no change, same as
4inarow.bas.

---

## 5b. `examples/winscroll.bas` — NO source changes, no library override needed either

Compiles with default flags:

```
python -m src.zxbc.zxbc winscroll.bas --arch zx81sd -o winscroll.bin
```

Unlike `scroll.bas`, `winscroll.bas` (character-cell window scroll:
`WinScrollRight/Left/Up/Down(row, col, width, height)`) has **no ROM
dependency at all** — it computes everything from `SCREEN_ADDR`/
`SCREEN_ATTR_ADDR` (read dynamically, not hardcoded) and only pulls in
`sysvars.asm` via `#require` (a link-time dependency tag, not a
textual `#include` — it doesn't risk the `INCBIN`-inline bug described
in [PRECAUTIONS.md](PRECAUTIONS.md) section 8). No zx81sd override was
needed; the shared zx48k library is used as-is via the normal fallback
mechanism. Verified by simulation (screen and attribute area fully
touched, clean `HALT` at `__END_PROGRAM`, no illegal writes).
**Confirmed working on real hardware.**

---

## 5c. `putchars.bas`/`puttile.bas` — one clean, one needed a zx81sd override

New example `examples/sd81/putcharstile.bas` (no official example to
adapt) exercises both libraries:

- **`putchars.bas`** (`putChars`/`getChars`/`paint`/`paintData`/
  `getPaintData`/`putCharsOverMode`): audited, **no ROM dependency at
  all** — every address is computed from `SCREEN_ADDR`/
  `SCREEN_ATTR_ADDR` read dynamically, and the file's own
  `#require "sysvars.asm"` is the safe link-time tag (see section 5b
  above), not a textual include. No zx81sd override needed; used as-is.
- **`puttile.bas`** (`putTile`, places a 16×16 px tile): **did need an
  override**. Unlike `putchars.bas`, it hardcodes the screen/attribute
  base as **immediate constants** — `add a,64` (screen, the Spectrum
  ROM's `$4000` high byte) and `add a,88` (attributes, `$5800`'s high
  byte) — instead of reading `SCREEN_ADDR`/`SCREEN_ATTR_ADDR`. Same bug
  class as `print42.bas`/`print64.bas`. Fixed the same way:
  `src/lib/arch/zx81sd/stdlib/puttile.bas` patches both constants once
  on entering `putTile()` (self-modifying code on the `ADD A,n`
  instructions themselves), reading the real high byte of
  `SCREEN_ADDR`/`SCREEN_ATTR_ADDR` at that point. Everything else
  (the interrupt save/restore dance, the stack-based pixel pushing) is
  architecture-agnostic and copied unchanged — the `ld a,i` / `jp po`
  idiom naturally never re-enables interrupts on zx81sd, since IFF2 is
  always reset here (the runtime never does `EI`).

**Debugging note**: the first simulation run of this example looked
broken (`paint()` seemingly painted only 1 of 3 rows, `putTile`'s area
looked empty) — turned out to be a false alarm caused by the example's
own final `PRINT AT` landing on the screen's last row (23), which
combined with `input()`'s cursor handling to trigger a normal scroll
that shifted the drawing up before the check ran. Moving the final
prompt to row 20 fixed it; `paint()`/`putTile()` were correct all
along. Verified with breakpoints right after each function returns
(not just at the end) to catch this class of false negative.
**Confirmed working on real hardware.**

---

## 6. `examples/maskedsprites.bas` → `examples/sd81/maskedsprites_sd81.bas`

**In progress — still not fully working.**

One substantial change: `WaitForNewFrame` (defined in the example
itself, not the library) rewritten to not depend on interrupts:

```diff
-    ld de,23672
-    ld c,a      ; A = C = minimumNumberofFramesToWaitSinceLastWait
-    READ_IFF2
-    ex af,af'    
-    ei          ; interrupts MUST be enabled before HALT
-    halt
+    ld de, FRAMES
+    ld c,a      ; C = minimumNumberofFramesToWaitSinceLastWait
+    call VSYNC_TICK ; guarantees at least one frame waited (replaces EI+HALT)
 wait:
     ld a,(de)
     sub (hl)
     cp c
-    jr c,wait
-    ld a,(de)
-    ld (hl),a
-    ex af,af'
-    ret pe
-    di
-    RET
+    jr nc,enough
+    call VSYNC_TICK
+    jr wait
+enough:
+    ld a,(de)
+    ld (hl),a
+    ret
```

**Why**: `23672` is the Spectrum ROM's `FRAMES` counter, automatically
incremented by the 50Hz IM1 interrupt. The original does one initial
`HALT` (waits for the interrupt) and then a loop that trusts the
interrupt to keep incrementing it in the background while the loop just
*checks* without waiting again. On zx81sd there are no interrupts
(permanent DI; the `$0038` vector is a `DI;HALT` trap, not a real
handler) — that `HALT` would never wake up. It's replaced with
`VSYNC_TICK` (polling the SD81 Booster hardware's VSYNC pulse counter
through a port, the same routine `PAUSE` already uses), called
explicitly on every loop iteration that needs to wait.

**Update — MSFS ported to the zx81sd mapper (block 7)**: the risk
above no longer applies. `src/lib/arch/zx81sd/stdlib/cb/maskedsprites.bas`
was created (a full override of the shared library, which stays
untouched): `SetBankPreservingINTs`/`GetBankPreservingRegs` rewritten
in hand-written ASM over port `$E7` (block 7, `$E000-$FFFF` — reserved
in our memory map for "data banking, maps, sprites"), and
`MaskedSpritesFileSystemStart` fixed at `$E000` instead of "whatever's
left up to `$FFFF`" (which assumed flat Spectrum RAM). The rest of MSFS
(hundreds of lines of block-bitmap arithmetic) is bank/address-agnostic
and was copied without touching a single line. Full detail, including a
real bug caught in the process (registers not preserved when written
in BASIC instead of ASM), in [MAP.md](MAP.md).

Despite the fixes above (confirmed by simulation and, partially, on a
real emulator/hardware), the library in its current state **still
doesn't fully work** — work in progress, don't consider this example
closed yet.

---

## 7. `examples/sd81/pong.bas` — classic transcription, one ASM change

Not an official `examples/` sample but a classic Sinclair-BASIC-style
transcription of Pong (GOSUB/line numbers), added directly under
`examples/sd81/`. It already uses lowercase key comparisons
("4","q","3","a"), matching the current keyboard scheme with no change
needed — the only change was replacing the screen sync:

```diff
     ASM
-    call VSYNC_TICK ; guarantees at least one frame waited (replaces EI+HALT)
+    call .core.VSYNC_TICK ; guarantees at least one frame waited (replaces EI+HALT)
     ; halt        ; Avoids screen flickering
     END ASM
```

**Why**: `vsync.asm` wraps `VSYNC_TICK` in
`push namespace core ... pop namespace`; calling it from an
`ASM ... END ASM` block that isn't inside that namespace needs the
full `.core.VSYNC_TICK` prefix — the same error pattern as in
`maskedsprites_sd81.bas` (see [PRECAUTIONS.md](PRECAUTIONS.md),
section 5). Without the prefix, the compiler gives
`Undefined GLOBAL label '.VSYNC_TICK'`.

---

## 8. `examples/sd81/block7test.bas` — no official equivalent, mapper test

A minimal program (not a transcription of any example) written to
confirm, in isolation, that the SD81 Booster's memory mapper provides
independent storage per page: it writes different patterns to pages 20
and 63 of block 7 (`$E000-$FFFF`) via `Map()` and checks they don't
overwrite each other. It was used to rule out the mapper as a cause
during the MSFS bug investigation (see [MAP.md](MAP.md)). Kept as a
reference example of direct `Map()`/`MapGet` usage over block 7.

---

## 9. `print42.bas`/`print64.bas` — new libraries (no example changes)

`stdlib/print42.bas` and `stdlib/print64.bas` (Britlion) implement a
42/64-column `PRINT` drawing pixel by pixel, instead of the normal
32-column `PRINT`. The zx48k version depends on the Spectrum ROM in
several places:

- `print42.bas`: `ld hl,$5C7B` (`UDG` sysvar), `ld de,15360`
  (fixed `CHARS-256`) and `ld a,(23693)` (`ATTR_P` sysvar).
- `print64.bas`: only `ld a,(23693)` (`ATTR_P`) — its 4px charset is
  its own, it doesn't use `UDG`/`CHARS`.
- Both, additionally, place the screen and attributes using
  **immediate** fixed-base constants (`add a,64` / `add a,88`, the
  high bytes of `$4000`/`$5800`) instead of reading a pointer — this
  works on the Spectrum because those addresses are ROM literals, but
  on zx81sd `SCREEN_ADDR`/`SCREEN_ATTR_ADDR` are variables (block 6,
  `$C000`/`$D800`).

`src/lib/arch/zx81sd/stdlib/print42.bas` and `print64.bas` were
created (full overrides): fixed sysvars → their zx81sd equivalents
(`UDG`/`CHARS`/`ATTR_P`, see `sysvars.asm`), and the two screen/
attribute base constants are **patched once on entering the function**
(self-modifying code on the `ADD A,n` instruction itself), reading the
real high byte of `SCREEN_ADDR`/`SCREEN_ATTR_ADDR` at that point — the
same thing the original ROM did with its own routines, only with a
variable value instead of a fixed one.

**Real bug caught during the port** (not in the example, in the
library itself): a `#include once <sysvars.asm>` naively placed at the
top of the file (BASIC level, outside any `ASM` block) produced
`error: illegal preprocessor character`, and placed inside the
function's `ASM` block it compiled but hung the program at runtime
(`HALT` at a garbage code address). Cause: if this library happens to
be the **first** one to include `sysvars.asm` in the whole program, it
drags in `bootstrap.asm`/`charset.asm` behind it — and the latter does
`INCBIN "specfont.bin"` (the complete font, not assembly text) — right
at that point in the source file. At BASIC level, the BASIC lexer tries
to tokenize binary source bytes as if they were text (hence the
"illegal preprocessor character"). Inside the function, the font binary
gets emitted literally in the middle of the function's compiled body,
and the CPU "executes" it as if it were instructions the moment control
flow falls there. Fix: don't include `sysvars.asm` at all from these
files — they trust that it's already included by the rest of the
runtime (`CLS`/`PRINT`, which any program using `print42`/`print64`
will also use), and only reference the already-namespaced symbols
(`.core.CHARS`, etc.). Full detail in [PRECAUTIONS.md](PRECAUTIONS.md)
and [MAP.md](MAP.md).

Verified by simulation (the usual Python harness): both test strings
(`tests_debug/print4264.bas`, companion repository) render legibly
pixel by pixel at the expected position, with no writes outside
screen/attributes/the file's own variables, and the program reaches its
normal `__END_PROGRAM`/`HALT`. **Confirmed working on real hardware.**

---

## 10. MCU command examples (unofficial, no example to adapt)

Six new example programs demonstrating the SD81 Booster MCU's command
surface (`stdlib/mcu.bas`/`joy.bas`), written directly for zx81sd —
none of them adapt an official `examples/` program. `examples/sd81/
filesystem.bas` already existed from an earlier session (it's what the
companion repository's `files.bas`/`FILES*` binaries were compiled
from) and was expanded to also demo `McuMkdir`/`McuRmdir`/`McuCopy`/
`McuMove`/`McuFree`, not just `McuCd`/`McuDirPrint`/`McuLoad`.

| File | MCU commands exercised | Status |
|---|---|---|
| `examples/sd81/filesystem.bas` | `McuPwd`, `McuCd`, `McuDirPrint`, `McuMkdir`, `McuRmdir`, `McuSave`, `McuCopy`, `McuMove`, `McuDel`, `McuFree` | **Confirmed working on real hardware** |
| `examples/sd81/wavplayer.bas` | `McuLoad` with a `.WAV` file (played directly by the MCU, not loaded into memory) | **Confirmed working on real hardware** |
| `examples/sd81/vgmplayer.bas` | `McuPlayVgm`, `McuContVgm`, `McuPauseVgm`, `McuStopVgm` | **Confirmed working on real hardware** |
| `examples/sd81/pegdemo.bas` | `McuLoadPeg`, `McuPlayPeg`, `McuStopPeg` | **Confirmed working on real hardware** (byte order below is correct) |
| `examples/sd81/joystick.bas` | `Joy()` (joy.bas, MCU cmd 21) | **Confirmed working on real hardware** |
| `examples/sd81/randomaccess.bas` | `McuFOpenZx`, `McuFSeek`, `McuFRead`, `McuFWrite`, `McuFClose` | **Confirmed working on real hardware** |

Memory-mapper access (`Map()`/`MapGet()`) already has a dedicated
example, `examples/sd81/block7test.bas` (see section 8 above), so no
new one was added for that.

**Compile-time bug found while writing these**: `stdlib/input.bas`
defines `input()` as a **function** (`a$ = input(maxChars)`), not the
native BASIC `INPUT` statement — using `input a$` (statement syntax)
after `#include <input.bas>` produces
`error: Cannot convert string to a value. Use VAL() function`, since
the identifier `input` is now bound to that function. All six examples
above end with `a$ = input(20)` to wait for a keypress, not
`input a$`.

**PEG byte encoding, resolved**: the SD81 Booster manual's Appendix B
documents the PEG instruction set as 16-bit words in big-endian order
(e.g. `LD R,XX` = `0R XX`), while `mcu.bas`'s own comment on
`McuLoadPeg` says the raw bytes it expects are "2 bytes little-endian
per instruction" — `pegdemo.bas` followed the `mcu.bas` comment
literally (value byte before opcode byte), and this has now been
**confirmed correct on real hardware**: the manual's big-endian
notation describes the instruction word's numeric value, while
`McuLoadPeg`'s wire format for cmd 40 is genuinely little-endian, as
documented in the library.

---

## Summary for the manual

| Example | zx81sd copy | Source changes | Compile flags |
|---|---|---|---|
| comecoquitos.bas | no copy needed if the original isn't touched | none | `--string-base 1 --array-base 1` |
| snake_en.bas | `snake_sd81.bas` | 1 line (UDG address) | none special |
| flights.bas | `flights_sd81.bas` | 3 kinds of change (POKE removed, 4× PEEK COORDS, 8× key case) | none special |
| 4inarow.bas | no copy needed | none | none special |
| scroll.bas | no copy needed | none (the fix was in the `stdlib/scroll.bas` library) | none special |
| winscroll.bas | no copy needed | none (no library override needed either — no ROM dependency) | none special |
| putchars.bas/puttile.bas (unofficial, `putcharstile.bas`) | `putcharstile.bas` in `examples/sd81/` | none for putchars.bas; `puttile.bas` needed a zx81sd override (hardcoded screen/attr base constants, same fix as print42/64) | none special |
| maskedsprites.bas | `maskedsprites_sd81.bas` | `WaitForNewFrame` rewritten (EI+HALT → VSYNC_TICK); `cb/maskedsprites.bas` library ported to the mapper (block 7) — **in progress, still not fully working** | none special |
| pong.bas (unofficial) | `pong.bas` in `examples/sd81/` | 1 ASM line (VSYNC_TICK namespace) | none special |
| block7test.bas (unofficial) | `block7test.bas` in `examples/sd81/` | n/a (written directly for zx81sd) | none special |
| print42.bas/print64.bas (libraries) | not applicable (not examples) | none — the fix was in `stdlib/print42.bas`/`print64.bas` | none special |
| filesystem.bas, wavplayer.bas, vgmplayer.bas, pegdemo.bas, joystick.bas, randomaccess.bas (unofficial) | all in `examples/sd81/` | n/a (written directly for zx81sd) | none special |

Pattern identified for future examples:

1. Look for `POKE`/`PEEK` on numeric literals: it's almost always a
   Spectrum sysvar that needs translating to its zx81sd equivalent
   address (see `src/lib/arch/zx81sd/runtime/sysvars.asm`).
2. `INKEY$` comparisons against uppercase control keys (`"S"`, `"Q"`,
   etc.): with the **current** keyboard scheme (direct press =
   lowercase, `SHIFT+letter` = uppercase) this already works exactly
   like on a Spectrum and **needs no change at all** — the case change
   documented above for `flights.bas` corresponds to an earlier version
   of `keyscan.asm` (see the "no longer needed" note in section 3.3)
   and is kept here only as a historical record of that
   already-generated copy.
3. Inline ASM code calling routines wrapped in `push namespace core`
   (like `VSYNC_TICK`) needs the `.core.` prefix if the `ASM` block
   calling it isn't already inside that namespace (see the `pong.bas`
   case above).
4. If a new library needs its own sysvars (`CHARS`/`UDG`/`ATTR_P`/
   `SCREEN_ADDR`/...), **don't do `#include once <sysvars.asm>` inside
   the file** — only reference the symbols with the `.core.` prefix,
   trusting that the rest of the runtime (`CLS`/`PRINT`) already
   included it. See the `print42.bas`/`print64.bas` case above and
   [PRECAUTIONS.md](PRECAUTIONS.md).
5. `stdlib/input.bas` defines `input()` as a function
   (`a$ = input(maxChars)`), not the native `INPUT a$` statement — once
   `#include <input.bas>` is used, `input a$` fails with
   `error: Cannot convert string to a value`. See the MCU examples case
   above.
