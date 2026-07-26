# Debug test log (DRAW3 / arc session)

Note on paths: this log was originally written in the companion,
test-only repository for the port (where the `.bas` files mentioned
here all lived in a `tests_debug/` directory). The examples considered
mature enough to publish have already been copied into this
repository, under [`examples/sd81/`](../../../../examples/sd81/)
(`flights_sd81.bas`, `snake_sd81.bas`, `maskedsprites_sd81.bas`,
`pong.bas`, `block7test.bas` — see [BASIC_CHANGES.md](BASIC_CHANGES.md)).
The rest of the one-off debugging sources mentioned here (`diag1-6`,
`t_arc*`, `trig_test`, `heaptest`, `keytest`...) only remain in the
companion repository, not this one.

Compiling each one (from the root of this repository):
```
python -m src.zxbc.zxbc examples\sd81\<name>.bas --arch zx81sd -o <name>.bin
python src\arch\zx81sd\tools\split_sd81.py <name>.bin <PREFIX>
```
(see [USAGE.md](USAGE.md) for the packager's detail.)

| Source                 | SD81 prefix  | What it tests                                                        | Result obtained |
|------------------------|--------------|---------------------------------------------------------------------|---------------------|
| `str_test.bas`         | STRTEST      | PRINT/STR$ of FLOAT (Phase 3)                                        | OK: 7 / 7.5 / -3.25 / 0 / 123.5 / -0.5 |
| `trig_test.bas`        | TRIGTST      | SQR/SIN/COS/EXP/LN/ATN with trivial arguments (Phase 4)              | OK: 3 / 1.41421 / 0 / 1 / 2.71828 / 1 / 3.14159 |
| `trig2_test.bas`       | TRIG2        | SIN/COS with NON-trivial arguments (1, 1.5708, 3.14159)              | OK: 0.8147(4?) / 0.5403 / 0.99999 / -0.99999 / 0 |
| `draw_arc_test.bas`    | DRAWARC      | DRAW+DRAW+CIRCLE combined (first arc attempt)                        | Only a vertical line appears, CIRCLE never shows |
| `t_line.bas`           | TLINE        | `DRAW 20,0` (2 args, no angle, no FP)                                | OK: horizontal line |
| `t_circle.bas`         | TCIRC        | `CIRCLE 60,30,20` alone                                              | OK: correct circle |
| `t_arc.bas`            | TARC         | `DRAW 20,0,3.14159` (arc alone, horizontal offset, 180°)             | BUG: vertical line (not horizontal, no arc) |
| `t_arc2.bas`           | TARC2        | `DRAW 30,10,1.5708` (asymmetric offsets, 90°)                        | BUG: vertical line with a slight rightward tilt |
| `t_arc3.bas`           | TARC3        | `PLOT 100,96` + `DRAW 20,0,3.14159` (centered, with margin)          | BUG: chaotic star-like pattern of several lines from the center; one goes off-screen into the attribute area |
| `diag1.bas`            | DIAG1        | Inline ASM: calls CD-PRMS1 (L247D) directly with z=40, A=pi/2, and prints mem-1/mem-3/mem-4/mem-0/line count | Blank screen — bug in the test itself (`#include` inside `ASM` puts executable code in the linear flow). Replaced by diag2 |
| `diag2.bas`            | DIAG2        | Same as diag1 but without manual includes: BASIC variables + normal PRINT | OK: exact expected values → CD-PRMS1 numerically correct |
| `diag4.bas`            | DIAG4        | With `-D DRAW3_DEBUG`: only prints N (number of segments captured by the draw3.asm hook) | OK: 16 → the capture hook works |
| `diag5.bas`            | DIAG5        | diag4 + buffer traversal loop (2 SD81 pages)                         | Didn't print; dropped, replaced by diag6 (1 page) |
| `diag6.bas`            | DIAG6/DIAG7  | diag4 + loop, 1 page. Its $152D dump + write breakpoints at $8004 located the bug | OK: 16/16. DIAG7 = identical, recompiled after the fix |
| `arcfix.bas`           | ARCFIX       | Reference test identical to a real Spectrum: `PLOT 100,100` + 2 arc DRAWs + CIRCLE | **OK after the fix**: hook + circle, matching the real Spectrum photo |

## DRAW3 (arc) bug — RESOLVED

**Root cause** (nothing to do with the FP calculator, whose math turned
out to be exact): `src/lib/arch/zx81sd/runtime/pixel_addr.asm` was
destroying register **D** (using it as scratch for V=191−Y). But
`draw.asm` (inherited from zx48k) saves the Bresenham Y coordinate in D
around the call (`ld d,b / call PIXEL_ADDR / ld b,d`), because the
Spectrum ROM's PIXEL-ADD ($22AC) preserves DE. As a result, every line
with a vertical component started internally with Y=191−y1, corrupting
COORDS and the drawing. Horizontal lines (t_line) and CIRCLE (which
doesn't go through that path) came out fine, which threw off the
initial investigation.

**Fix**: PIXEL_ADDR rewritten to use B as scratch (it was already being
destroyed, same as the ROM) and preserve D and E. Verified on hardware
with ARCFIX (identical to the real Spectrum's result) and DIAG7.

**Localization method**: a `#ifdef DRAW3_DEBUG` hook in draw3.asm
(enabled with `-D DRAW3_DEBUG`) that captures, for every segment:
|Dy|,|Dx|, signs and the previous COORDS in a buffer
(`DRAW3_DEBUG_BUF`); a memory dump of the buffer in EightyOne's
debugger + write breakpoints on COORDS ($8004/$8005). The dump showed
the accumulated FP position was perfect and that COORDS ended up wrong
after every line → the bug was in __DRAW/PIXEL_ADDR, not in
fp_calc.asm or draw3.asm.

## Source files modified/created in this session (FP engine + arc)

- `src/lib/arch/zx81sd/runtime/fp_calc.asm` — Phases 1-5 (the
  CALCULATE engine, trig/log/exp/sqrt, and now STK-TO-A/STK-TO-BC/
  CD-PRMS1 for the arc). Also had `#include once <stackf.asm>` added
  (an unrelated bug: it's always included in every zx81sd binary, so it
  had to be self-sufficient).
- `src/lib/arch/zx81sd/runtime/draw3.asm` — NEW. An override of
  `zx48k/runtime/draw3.asm` that replaces calls to fixed ROM addresses
  with the routines ported in `fp_calc.asm`. Includes trace
  instrumentation behind `#ifdef DRAW3_DEBUG` (off by default; enabled
  by compiling with `-D DRAW3_DEBUG`).
- `src/lib/arch/zx81sd/runtime/pixel_addr.asm` — FIX for the arc bug:
  now preserves D and E (it used to destroy D, breaking draw.asm's
  Bresenham on every non-horizontal line).
- `src/lib/arch/zx81sd/runtime/fp_tostr.asm`, `printf.asm`, `str.asm` —
  from Phase 3 (PRINT/STR$ of FLOAT), unchanged in this session.

## Sound: BEEP and PLAY (SD81's AY ZonX chips)

| Source          | SD81 prefix  | What it tests                                             | Result |
|-----------------|--------------|------------------------------------------------------------|-----------|
| `beeptest.bas`  | BEEPTS2      | Variable BEEP (FP runtime) + constant BEEP (13/14 clock fix in __BEEPER) | OK: scale + DO/DO' + LA 440 |
| `playtest.bas`  | PLAYTS2      | PLAY over 3 channels + AY/beeper comparison               | OK (watch out: lowercase notes = one octave down!) |
| `aycal.bas`     | AYCAL        | AY vs beeper pairing by semitone                          | Used to detect the offset |
| `aycal2.bas`    | AYCAL2       | Timeable durations + direct pairing                       | FFT: beeper 434.5 (correct, emulator pacing), AY 220 |
| `aycal3.bas`    | AYCAL3       | Same with UPPERCASE notes                                 | OK: unison 440/440 |

Lesson from the "phantom octave" investigation: in PLAY's MML (128K
BASIC semantics), lowercase notes sound one octave below the current
octave. The initial tests used lowercase and the AY was sounding at
220 Hz *by design*. The emulator, the divider table (1.625 MHz) and the
beeper (3.25 MHz) were all correct. Verified with an FFT over recorded
audio output. As a bonus, a real latent EightyOne bug got fixed along
the way (the AY's clock kept the hardware-dialog card's setting instead
of the ZonX one forced by the SD81: it was missing a call to
Sound.InitDevices() after forcing machine.aytype).

## MCU library (SD81 Booster) — `zx81sd/stdlib/mcu.bas` + `joy.bas`

| Source         | SD81 prefix  | What it tests                                               | Result |
|----------------|--------------|------------------------------------------------------------|-----------|
| `joytest.bas`  | JOYTS2       | `Joy("QAOPM")` (cmd 21) + local validation + INKEY$ echo    | OK |
| `mcutest.bas`  | MCUTST       | VERSION, GET/SETBYTE, PWD, SAVE+LOAD+verify, DEL, FREE, RTC, BAT, DIR, AY2 by registers, AyPlay | pending |
| `maptest.bas`  | MAPTST       | `Map(block,page)`/`MapGet` — the $E7 mapper: signatures in 2 pages switching block 5, and verification | OK |
| `exttest.bas`  | EXTTST       | Non-MCU extensions: `HexPoke` (*HEX), `MemMove` (*LDIR/*LDDR, stdlib), `StrInv`/`StrBold` (*INV/*BOLD) | OK |
| `ftest.bas`    | FTEST        | F_* handles: SAVE, F_OPEN_ZX81 (cmd 58), F_SEEK, F_READ with verification, F_WRITE+reread, F_CLOSE, DEL | OK |
| `lstest.bas`   | LSTEST       | Native LOAD/SAVE/VERIFY ... CODE statements → SD (runtime override load.asm/save.asm, cmd 9/10): SAVE+LOAD+verify, VERIFY ok/corrupt (ERR 26), missing file (ERR 26) | OK |

Architecture: `mcu.bas` contains the protocol primitives in ASM
(McuSend/McuRecv/McuSendBlock/McuRecvBlock — the *Block ones are the
critical path for LOAD/SAVE/F_READ/F_WRITE) and wrappers for every
command in the manual (system, files, F_* handles, hardware, voice,
AY2/VGM/PEG, RTC/BAT). Automatic ASCII↔ZX81 conversion in the text
commands. `joy.bas` is a thin layer over `mcu.bas`.

Protocol notes (extracted from the emulator's SD81Booster.cpp):
- After EVERY operation on $A7, the change in bit 7 of $AF is expected.
  NEVER write to $AF (MCU reset).
- Z80→MCU strings: length byte + data (the MCU converts ZX81→ASCII
  except for "raw" commands: JOY, BINARY_SAY, F_OPEN).
- MCU→Z80 streams (PWD/DIR/TYPE/FREE_TXT): request each character by
  writing CMD_NEXTCH ($0D); end = EOT ($6F); the status arrives after.
- Fixed-length responses (LOAD, FREE, RTC, BAT, F_READ): a burst of
  bytes reading $A7 with a clock wait between each one.
- F_OPEN: confirmed in the firmware (COMMANDS.cpp) that the MCU
  assigns the handle and returns it (the manual was wrong and has been
  corrected). Added F_OPEN_ZX81 (58) to the library and the emulator.
- OPENDIR/GETROWLEN/GETROW (16-18) aren't emulated in EightyOne: only
  test them on real hardware.

## Integration test: comecoquitos.bas (official zxbasic example)

| Source | SD81 prefix | What it tests | Result |
|---|---|---|---|
| `examples/english/comecoquitos.bas` | COMECO | Complete 1985 game: FP, strings/slices, arrays, UDGs, block graphics, color/FLASH/BRIGHT, INKEY$, BEEP, RND | OK — identical to the Spectrum .tap |
| `fpleak.bas` | FPLEAK | Detector for FP stack leaks by block (reads $8024 after each idiom) | Helped narrow it down; the "leak" was UDG corruption |
| `blocktest.bas` | BLKTST | The 16 block graphics CHR$(128)-143 | OK after the PO_GR_1 fix |

Three runtime bugs caught with this game (commits 9903c866 and
9a24059e):
1. UDG pointed 128 bytes past the end of the font (96 chars, not 256):
   POKE USR CHR$ was clobbering runtime code → hang on the calculator's
   first use. Fix: a dedicated 21-UDG area.
2. INKEY$ returned uppercase; the Spectrum's L mode (and the era's
   programs) use lowercase. Fix: lowercase keyscan table.
3. PO_GR_1 (blocks CHR$(128)-143) generated corrupt patterns (OR into
   the wrong register + swapped left/right quadrants). Fix: the ROM's
   literal algorithm.

RECIPE for classic examples transcribed from Sinclair BASIC: compile
with `--string-base 1 --array-base 1` (1-based indexing). Without it,
string-slicing collisions come out shifted by one position (not a bug
in the port: it happens the same way on zx48k).

## Heap at $8100 + EightyOne tape traps — RESOLVED (2026-07-04)

| Source | SD81 prefix | What it tests | Result |
|---|---|---|---|
| `tests_debug/heaptest.bas` | HEAPA..HEAPE | Dynamic memory manager (3 phases: char-by-char growth, large REALLOCs, STR$ in a loop) with the heap at different addresses | Bisection that isolated the bug |
| `tests_debug/memtest.bas` | MEMTST | R/W pattern dependent on address in $8100-$BFFF (2 passes) | OK — ruled out hardware/paging |
| `tests_debug/inputtest.bas` | INTEST | Minimal, isolated INPUT() | Reproduced the hang |
| `examples/sd81/flights_sd81.bas` | FLIGHT | Flight simulator: PEEK COORDS ($8004/5), FP-intensive, INPUT | Adaptation of examples/flights.bas |

Two chained bugs, caught on 2026-07-04:

1. **Compiler (`src/arch/zx81sd/backend/main.py`)**: `heap_size`/
   `heap_address` were registered with `ADD_IF_NOT_DEFINED`, but the
   generic Z80 backend already defines them earlier (4768 / None) →
   zx81sd's values ($8100 / 16127) were never applied and the heap
   ended up inline (DEFS) inside the executable area, wasting 4768
   bytes and limiting the heap. Fix: direct assignment of
   `OPTIONS.heap_size/heap_address` (the CLI can still override it).

2. **Emulator (`Eightyone2/src/ZX81/rompatch.cpp`, `PatchTest`)**: the
   ZX81 ROM's tape traps ($0207/$02FF/$031E/$0356) were triggered by
   comparing PC + a **flat** `memory[pc]` read, which keeps reading the
   ROM even though the SD81 has RAM mapped. With the heap in EQU, the
   runtime moves $12A0 bytes down and the __DIVU16_FAST division lands
   on $02FF → the SAVE trap sets `DE=1` mid-division → stable garbage
   quotient → an infinite digit loop in __PRINTU_LOOP (PUSH AF with no
   matching pop) → the stack descends, wiping out the runtime. Builds
   with an inline heap were immune by coincidence: the 4 trap addresses
   fell inside the DEFS block (data, the PC never passes through
   there). Fix: `PatchTest` reads the byte with `zx81_PatchPeek()`
   (mapper-aware). This bug does NOT exist on real hardware (there are
   no traps).

Methodology that solved it: deterministic simulation of the binary
with Python's `z80` library (pip install z80) — code-area integrity
diff after each stretch + breakpoints comparing registers against
EightyOne. The binary was correct in pure Z80 → the divergence was in
the emulator. Harness in the session's scratchpad (runsim*.py,
reproducible).

## PRINT scroll jumping into the Spectrum ROM — RESOLVED (2026-07-04)

Third bug in the flights.bas chain (wind=10, dir=100 → HALT): zx81sd's
`print.asm` had kept, from zx48k, the fallback
`__SCROLL_SCR EQU 0DFEh` (the Spectrum ROM's CL-SC-ALL routine). On
zx81sd there's no ROM: the first PRINT that overflowed the screen did a
CALL to whatever compiled BASIC line happened to occupy $0DFE → wild
execution → a gosub RETURN popping garbage → HALT. It depended on the
input because the number of digits typed moved the cursor: with wind
"1"/"0" the text never overflowed; with "10"/"100" it did. No previous
test caught this because they all use PRINT AT (never scroll).

Fix: the buffer-based implementation (`__ZXB_ENABLE_BUFFER_SCROLL`,
scrolls via SCREEN_ADDR/SCREEN_ATTR_ADDR) is now the only branch of
__SCROLL_SCR in zx81sd/runtime/print.asm. Verified with the Python
simulator + scripted keyboard: the game's main loop keeps SP stable
over thousands of steps. Future note: check for any other EQU/CALL to
absolute Spectrum ROM addresses when porting files from zx48k (grep
already done: none remain in the zx81sd runtime).

## New keyboard scheme: uppercase, CAPS LOCK and symbols — 2026-07-04

| Source | SD81 prefix | What it tests | Result |
|---|---|---|---|
| `tests_debug/keytest.bas` | KEYTST | Interactive INKEY$: prints the ASCII code + character of every key | Verified by exhaustive simulation (see below); pending manual testing on the emulator/hardware |

The ZX81's physical keyboard doesn't distinguish upper/lowercase per
key: SHIFT+letter gives a symbol, not the uppercase of that letter.
Until now `keyscan.asm` only ever returned lowercase. New scheme
(`src/lib/arch/zx81sd/runtime/io/keyboard/keyscan.asm`, rewritten from
scratch):

- No modifier: lowercase (same as before — comecoquitos, snake,
  flights, row4 keep working without touching a line, because none of
  them use SHIFT).
- `SHIFT + letter`: UPPERCASE of that letter.
- `SHIFT + "2"`: toggles a persistent CAPS LOCK (silent, prints
  nothing).
- CAPS LOCK active: lowercase becomes uppercase; SHIFT still gives
  uppercase the same way (it's an OR, no interaction — decision made
  with the user).
- `"."` alone: `.`
- `SHIFT + "."`: `,` (same as a real ZX81).
- `"." + another key`: the symbol printed on the ZX81 keyboard for that
  key (`:` with Z, `)` with O, RUBOUT with 0, etc. — the ZX81's old
  SHIFT table, now reachable with "." instead of SHIFT, since SHIFT has
  been redefined to give uppercase).

Required rewriting the scan: it used to stop at the first row with
anything pressed (one key at a time was enough). Now two dedicated port
reads are needed for SHIFT (row 0) and "." (row 7, column 1), plus a
scan of the other rows looking for a third key, excluding those two
positions (`FIND_OTHER` routine). The `SHIFT+"2"` combo uses a
persistent state byte with edge detection so it doesn't toggle
repeatedly while held down.

Verified with a Python simulation harness (`z80`, same methodology
already used for the heap bugs): `__ZX81SD_KEYSCAN` is called directly,
injecting the exact row bits of each combination through the I/O
callback (Z alone, SHIFT+Z, "."+Z, SHIFT+2 held for 4 consecutive
polls, etc.), without dealing with the complexity of a real keyboard.
The table and state offsets (`_KBD_*`, all LOCAL to the PROC, don't
show up in the `.map`) were located by searching for
`UNSHIFT_TABLE`'s byte pattern ("zxcvasdfg") in the binary and
computing the rest by fixed offset (each table takes 39 bytes). All 12
cases in the design table matched exactly, including the CAPS LOCK
debounce.

### 2026-07-04 fix: the "." modifier moved from keyscan to input.bas

When testing it on the emulator, the user found that `"."+key`
(intended to give the ZX81 symbol by pressing both at once, like
SHIFT+letter) was impractical from `INPUT`: `PRIVATEInputWaitKey`
commits to the `"."` key as soon as it detects it alone, without giving
the second key time to actually arrive at the same time (unlike
SHIFT+letter, which can comfortably be held with the other hand). The
user's correct diagnosis: *"symbol handling shouldn't live in keyscan
but in INPUT.bas"*.

Fix: `keyscan.asm` now treats `"."` like any other key — unshifted
gives `.`, with SHIFT gives `,` (same as a real ZX81), with none of the
"third key" logic for the dot (the row-7 exclusion in `FIND_OTHER` was
removed entirely, no longer needed). The `UNSHIFT_TABLE`/
`SYMBOL_TABLE`/`CAPS_TABLE` tables were promoted from `LOCAL` to file
scope (`__ZX81SD_` prefix) and a new routine was added,
`__ZX81SD_SYMBOL_FOR(char)`, which does the reverse
UNSHIFT_TABLE→SYMBOL_TABLE lookup given an already-decoded character.

Symbol composition now lives in `stdlib/input.bas` as a sequential
"dead key": on reading `"."`, the `input()` function reads the NEXT key
separately (with no simultaneity requirement) and calls
`PRIVATEInputSymbolFor()`; if there's a symbol, it's appended; if not,
the literal dot is appended and the second key is processed normally
(DEL, ENTER, or one more character).

A bug of my own caught during the implementation (before the user ever
saw it): `"."` + `"0"` resolves to RUBOUT (12) via `SYMBOL_TABLE` (it's
the actual symbol the ZX81 prints over the "0" key), which would delete
the previous character when typing any decimal ending in ".0" (very
common: "3.0", "10.0"...). That value was explicitly excluded in
`input.bas` — RUBOUT is already reachable unambiguously with SHIFT+0
(which is comfortable to hold at the same time). Verified with a
full-program simulation (scripted typing "1",".","0",ENTER →
`a$="1.0"` correctly, and "."," o",ENTER → `a$=")"`), not just the
isolated function.

`tests_debug/keytest.bas` (KEYTST) is still the interactive `INKEY$`
tester; `tests_debug/inputtest.bas` (INTEST) is the same old mini
`INPUT()` test, now also useful for testing symbol composition by hand.

### 2026-07-04 refinement: two dots in a row = a literal dot

With the previous design, `"."` + a letter with an associated symbol
(e.g. Z → `:`) always resolved to that symbol — there was no way to
literally write a dot followed by that letter. User request: pressing
`"."` twice in a row should confirm the first dot as literal (the
redundant comma that used to come out of `"."+"."`, via
`SYMBOL_TABLE`, is no longer needed — it's already reachable directly
and unambiguously with `SHIFT+"."`), and whatever key comes after is
read as a fresh keypress with no combination. So, to write ".Z" you
type "." "." "Z".

Implemented in `input.bas`: if the second key read after a "." is also
a ".", the dot is appended, the second keypress is discarded (prints
nothing by itself, `LastK=0`) and the loop goes back to reading a fresh
key. Verified with the same full-program simulation:
`"."+"."` → `a$="."`; `"."+"."+"z"` → `a$=".z"` (without forming the
`:` symbol).

## scroll.bas — RESOLVED 2026-07-04 (new library, example unchanged)

| Source | SD81 prefix | What it tests | Result |
|---|---|---|---|
| `examples/scroll.bas` | SCROLL | The 4 pixel-by-pixel scrolls (Right/Down/Left/Up) over a 60×60 px window, 30 rounds | Simulated 1200M ticks with no HALT/RST38; pending viewing on the emulator (the example does 1920 scrolls of up to 100×100 px, takes a while) |

`src/lib/arch/zx48k/stdlib/scroll.bas` had no zx81sd override — the
zx48k version was used as-is, and its 8 subs (`ScrollRight/Left/Up/
Down` + their `*Aligned` variants) all call `call 22ACh`, the Spectrum
ROM's *PIXEL-ADD* routine. On zx81sd there's no ROM mapped: that
address lands in the middle of the program's compiled code, and the
reported HALT (`RST 38` in the trace) was just whatever byte happened
to be there.

Fix: `src/lib/arch/zx81sd/stdlib/scroll.bas`, an identical copy except
the 8 calls to `$22AC` are replaced with `call PIXEL_ADDR` (our own
routine, `runtime/pixel_addr.asm`, already used by `plot.asm`/
`draw.asm`). The register contract is IDENTICAL to the ROM's (A=191,
B=Y, C=X → HL=offset, A=X AND 7, destroys B, preserves D/E), so not a
single line of the scroll loop bodies needed touching, only the call
site. `SP.PixelDown`/`SP.PixelUp` (from zx48k/runtime/SP/) didn't need
copying: they're pure arithmetic over `SCREEN_ADDR`, no ROM involved,
and already worked the same way on zx81sd (resolved through the normal
zx48k fallback mechanism when there's no override).

`examples/scroll.bas` itself needed no source change — like
`4inarow.bas`, the problem was entirely in the library, not the
program. Added to `BASIC_CHANGES.md` with the same note.

## maskedsprites.bas — RESOLVED 2026-07-04 (source change, not a library one)

| Source | SD81 prefix | What it tests | Result |
|---|---|---|---|
| `examples/maskedsprites.bas` → `examples/sd81/maskedsprites_sd81.bas` | MASKED | Masked sprites (AND+OR) with MSFS, 10 animated sprites | Simulated 1000M ticks with no HALT/RST38/illegal write; PC advances across a wide range of addresses (not stuck) |

Unlike `scroll.bas`, here the problem WAS in the example itself
(`WaitForNewFrame`, defined directly in `examples/maskedsprites.bas`,
not in the `cb/maskedsprites.bas` library): it does `EI` + `HALT`
waiting for the Spectrum ROM's 50Hz IM1 interrupt, comparing against
the ROM's `FRAMES` counter at absolute address `23672`. On zx81sd
interrupts are permanently disabled (the whole runtime runs with `DI`;
the `$0038` vector is only a `DI;HALT` trap, not a real handler) — that
`HALT` never wakes up. Confirmed by the trace: the simulator ended up
with `m.halted=True` exactly at `WaitForNewFrame`'s `HALT` after ~31M
ticks.

Fix in `examples/sd81/maskedsprites_sd81.bas`: `WaitForNewFrame`
rewritten to use `VSYNC_TICK` (`runtime/vsync.asm`, already used by
`PAUSE`) instead of `EI+HALT` — polls the SD81 Booster's hardware
VSYNC pulse counter through a port ($AFh), with no dependency on
interrupts. The original algorithm did ONE initial `HALT` and then a
loop that checked `FRAMES` WITHOUT waiting again (trusting the
interrupt to keep incrementing it in the background); since nothing
increments it on its own on zx81sd, the loop calls `VSYNC_TICK`
explicitly on every round it still needs to wait.
`GetInterruptStatusInBorder` was left untouched (never called in the
main loop, only appears commented out — kept only so the end-of-file
compile check doesn't fail with "unused function").

### 2026-07-04 update: MSFS genuinely ported to the mapper (block 7)

The `$5B5C`/`$7FFD` risk from above **no longer applies**: at the
user's request ("why don't we use the block 7 we have for banking?"),
`src/lib/arch/zx81sd/stdlib/cb/maskedsprites.bas` was created, a full
override of the shared library (which stays untouched, Boriel's rule).
Design (see also `BASIC_CHANGES.md`):

- **Key finding**: MSFS's functions (`RegisterSpriteImageInMSFS`,
  `FindFirstUnusedBlockInMSFS`, etc.) are bank/address-agnostic — they
  only call `GetBankPreservingRegs`/`SetBankPreservingINTs` and read/
  write the BASIC variable `MaskedSpritesFileSystemStart`. By
  rewriting those two primitives (using port `$E7` over **block 7**,
  `$E000-$FFFF` — reserved in our memory map exactly for "data
  banking, maps, sprites") and that address's calculation in
  `InitMaskedSpritesFileSystem()` (fixed at `$E000` instead of
  "whatever's left up to `$FFFF`", which assumed flat Spectrum RAM),
  the rest of the file (hundreds of lines of block/bitmap arithmetic)
  was copied literally without touching a line.
- `CheckMemoryPaging()` returns `0` (honest: zx81sd has no Spectrum
  bank-5/7-style dual visible screen) with no effect on MSFS, because
  MSFS's functions don't consult that function to decide whether to
  use the bank — they always do it unconditionally.
- `SetVisibleScreen`/`GetVisibleScreen`/`ToggleVisibleScreen`/
  `CopyScreen5ToScreen7`/`CopyScreen7ToScreen5`/`SetDrawingScreen5`/
  `SetDrawingScreen7`/`ToggleDrawingScreen` → safe stubs (real
  double-screen buffering isn't covered; dead code in this example
  since `memoryPaging=0`, but they no longer touch `$5B5C`/`$7FFD` in
  case something calls them directly in the future).

**Real bug found during the implementation** (not by the user, caught
with the simulation harness itself): my first attempt wrote
`SetBankPreservingINTs`/`GetBankPreservingRegs` in plain BASIC instead
of hand-written ASM. That broke the register contract documented in
the original file itself ("Preserves: D, E, H, L") which
`RegisterSpriteImageInMSFS`'s ASM code and friends take for granted
(for example, so as not to lose `spriteImageAddr`, which arrives in
HL) — a compiled BASIC function uses registers freely inside with no
guarantee of preserving them. Result: all 6 test sprites registered at
the SAME address (`$0C07`) instead of distinct ones. Both primitives
were rewritten in hand-written ASM, with the exact same contract as
the original (only touching A, B, C).

Verified by simulation: the 6 register addresses (`regHero0`,
`regFoe00`, `regFoe20-23`) come out sequential every 96 bytes exactly
(`$E010, $E070, $E0D0, $E130, $E190, $E1F0`, matching
`$E000+n*96+16`), without triggering `STOP`, and the main loop
(`WaitForNewFrame`) is reached repeatedly with no hang after 1000
million simulation ticks with no `HALT`/illegal write.

Known limitation of the Python simulator used in this session: it
doesn't model the memory mapper (`OUT` to `$E7` is a no-op in the
simulation, all RAM is treated as flat) — it can't validate that the
*physical* page swap genuinely works, only that the Z80 logic is
correct assuming it does. The definitive validation is on the
emulator/real hardware.

### 2026-07-04, second round: still going to HALT on real hardware

With the fix above already compiled, on the real emulator it still
triggered `__STOP` (same symptom: `RegisterSpriteImageInMSFS` returns
0). The trace confirmed the problem was in `SetBankPreservingINTs`,
which did the `OUT` to port `$E7` by hand instead of calling `Map()`
(mcu.bas): it wrote `A=7` (block, without combining it with the page)
with `B=page`. My initial hypothesis was that the hardware might be in
simple mode (where the data byte must carry page AND block combined,
`(page AND 31)<<3 | block`, and with only `A=7` it would be interpreted
as page=0) — **the user corrected this**: the SD81 loader leaves the
mapper in full mode from the `LOAD *MAP 7,63` line onward, until the
next reset, so that specific explanation doesn't fit (in full mode only
A's 3 low bits matter, the same in both versions). The exact cause was
still unconfirmed at the time of writing this.

`SetBankPreservingINTs` was changed to call `Map()` (code already
proven in other contexts) instead of repeating the port logic by hand,
preserving D,E,H,L around the call with manual `push`/`pop` (`Map()`
itself preserves nothing). This had a side effect: `Map()` was no
longer referenced from BASIC anywhere (only from hand-written ASM), and
the compiler's dead-code eliminator removed it from the binary →
`Undefined GLOBAL label '._Map'`. Solved with an explicit, redundant
BASIC call to `Map(7, MaskedSprites_MSFS_Page)` inside
`InitMaskedSpritesFileSystem()` (commented as such — the compiler's
usage analysis doesn't count calls made from ASM).

Verified again in simulation (the same 6 sequential addresses, no
`STOP`) — but it still failed on the real emulator. The switch to
`Map()` was, as the user pointed out, a no-op ("the library's Map does
exactly the same thing as the raw out").

### REAL root cause (third round, 2026-07-04): the FSB is never initialized

The user's trace showed `FindFirstUnusedBlockInMSFS` scanning the
ENTIRE free-space bitmap (the FIND-INT loop, 254 lines of RRCA/DEC E)
and exiting through the `full` branch (`SCF/RET` → `JR C` → `LD HL,0`):
**every block appeared "used"**. `__EQ16` (the initial suspect) worked
perfectly — `regHero0` really was 0.

Cause: **neither our version nor the original zx48k one ever clears the
FSB** (the bitmap bytes at `start+2..start+1+l`). On the Spectrum
that's not needed: the ROM's RAM test leaves all memory zeroed at
boot, so the bitmap is born "all free" for free. On zx81sd, block 7's
page arrives with factory garbage → every bit set to 1 → "no free
blocks" → `RegisterSpriteImageInMSFS` returns 0 → `STOP`.

**Why the Python simulator gave a false OK twice**: its RAM also starts
at zero, just like a Spectrum's after the ROM test — exactly the
condition that hides the bug. Methodology lesson added to the harness:
to validate code that reads uninitialized memory, fill all unloaded RAM
with garbage (`$FF`) before simulating. With dirty RAM, the unfixed
binary reproduces the `STOP` (the trace's failure mode) and the fixed
binary passes completely (6 correct registers, main loop reached).

Fix (3 lines + a comment in `InitMaskedSpritesFileSystem`): a
`FOR j = start+2 TO start+1+l: poke j,0: NEXT` loop after computing the
FSB's size.

Along the way, it was also confirmed with
`examples/sd81/block7test.bas` (BLOCK7 prefix) that the mapper works
perfectly: different patterns written to pages 20 and 63 of block 7
survive the page switch (independent content per page). The mapper was
never the problem.

### 2026-07-04, fourth round: sprites as vertical lines — resident page

With the FSB fix, on the real emulator MSFS now initialized correctly
(screen: `Init MSFS at 57344`, `Free Blocks = 85`, and all 6 registers
with the EXACT values predicted by the simulation) but the sprites were
being drawn as vertical lines instead of their actual graphics.

Cause (a design oversight of this override, not the original):
`SaveBackgroundAndDrawSpriteRegisteredInMSFS` — the function that draws
in the main loop and manufactures shifted images on demand — accesses
MSFS **without wrapping it in Get/SetBank**. In the original design it
doesn't need to: on 128K, bank 7 stays mapped at `$c000`
(`SetDrawingScreen7`) and on 48K, MSFS is always visible in flat RAM.
Our first version "released" block 7 back to page 63 when restoring
after `Init`/`Register...` → drawing read masks and graphics from page
63 (garbage) → vertical lines. The simulator couldn't detect this:
with no mapper modeled, page 20 and 63 are the same flat RAM.

Fix: MSFS's page stays **resident** in block 7 from init onward —
`SetBankPreservingINTs` with a value ≠ 7 only records the number, it
doesn't unmap (the "release back to page 63" was an invention of this
override, nothing needs it). Documented in the library's header: if a
program uses block 7 for its own banking, it must remap its own page
and call `SetBankPreservingINTs(7)` before using MSFS again.

## Chroma81 colour mode not activated by Spectrum mode alone — RESOLVED (2026-07-05)

Found on real hardware, not caught by the emulator: activating
Superfast HiRes Spectrum mode (`POKE 2045,172` / `ld ($07FD),a`) turns
on the Spectrum-compatible screen layout, but does **not** by itself
turn on Chroma81 colour on a real SD81 Booster — everything showed up
monochrome despite `INK`/`PAPER`/attributes being written correctly.
EightyOne shows colour regardless of this step, which is an **emulator
bug** (color should also require the same explicit activation to match
real hardware) — needs reporting/fixing in the EightyOne repository
separately, not something to work around here.

Fix: `tools/boot1.asm` (stage 1 bootstrap) now also writes to the
Chroma81 port (`$7FEF`) right after activating Spectrum mode:

```
ld   bc, $7FEF               ; Chroma81 port: set known state
ld   a, 39                   ; bit5=1 color on, bit4=0 char-code mode
out  (c), a
```

`tools/boot1.bin` reassembled with `zxbasm.py` (34 bytes, was 27 —
exactly the 3 new instructions' bytes: `01 EF 7F` / `3E 27` / `ED 79`).
This is the shared stage 1 loader used by every zx81sd program, so no
program needs recompiling — just copy the updated `BOOT1.BIN` to the
SD card.

## Screen/attributes not cleared at program start — RESOLVED (2026-07-06)

Reported after real-hardware testing: block 6 (screen RAM, $C000-$DFFF)
is physical RAM that survives a reset, unlike a real Spectrum ROM cold
boot which always starts from a cleared display file. Any zx81sd
program that doesn't call `CLS` itself (many quick debug tests just
`PRINT` sequentially) could show leftover pixels/attributes from
whatever ran before it.

Fix: `runtime/bootstrap.asm`'s `SD81_INIT_SYSVARS` (already run via
`#init` before every program, right after setting `SCREEN_ADDR`/
`SCREEN_ATTR_ADDR`/`ATTR_P`) now also clears the physical screen:
6144 bytes at `$C000` to 0, 768 bytes at `$D800` to the just-set
`ATTR_P` value ($38 = INK 0/PAPER 7). Same approach as the shared
`cls.asm`, inlined here to avoid depending on CLS being linked into
every binary.

This is in the shared bootstrap, so every zx81sd binary gets it
automatically on recompilation — no per-test changes needed. Verified
by simulation: pre-filled screen/attr RAM with garbage before boot,
confirmed both regions read back as fully cleared (0 / $38) right
before the program's own first PRINT, via a Python harness tracing
PC/BC/HL through the LDIR loops.

## SD81DBufOn/SD81DBufOff/SD81WaitVSync — double buffer library, port $E7 (2026-07-07)

New `stdlib/dbuf.bas`: wraps the SD81 Booster's present-blit double
buffer feature. Ported from `SD81-Booster/EXAMPLES/DBUF/bounce.asm`
(reference demo authored alongside the FPGA feature), adapted for
zxbasic because memory-mapped IO is disabled by `tools/boot1.asm`
(`POKE 2056,0`) before any compiled program runs, so the classic
`POKE 2057` control path is unusable from zxbasic — everything goes
through port `$E7`'s pseudo-block-8 encoding instead (`OUT` with
A=8, B=32+frontBlk to enable, B=0 to disable). `boot1.asm` also leaves
the mapper in full-paging mode permanently, which is exactly the state
this path requires, so it works unconditionally on every zx81sd binary.

The front buffer is *not* one of the program's own blocks 0-5 (code/
data, see `_PAGE_MAP` in `backend/main.py`), nor block 6 (the live
screen) nor block 7 (data banking, `Map()` in `mcu.bas`) — it lives in
the FPGA's private screen shadow RAM, addressed with its own
independent 0-7 index. Per the hardware spec, blocks 4/5 are the
recommended choice and 0-3/6-7 should be avoided; the library and demo
use 5.

`examples/sd81/bounce_sd81.bas` (mirrored to the private repo as
`tests_debug/bounce_sd81.bas`, packaged as `BOUNCE.P`/`BOUNCEP8.BIN`) is
a straight port of the reference demo's logic (erase/~6ms delay/move/
draw synced to VSYNC, SPACE toggles dbuf live, M freezes movement, Q
quits) — much shorter than the original because zx81sd's boot already
sets up the screen address, Superfast HiRes Spectrum mode, Chroma81
colour and the initial screen/attribute clear (see the previous
section), none of which bounce.asm can assume when running standalone.

This is the **first test of the port $E7 dbuf path** — only the
`POKE 2057` path had been validated on real hardware before this.
Verified so far only in simulation (Python `z80` harness): confirmed
`SD81DBufOn(5)` emits exactly `OUT $E7` with A=8/B=37 (bit5 enable,
front=5) and the border changes to green as expected; the main loop
runs correctly through many frames (10M+ simulated T-states) with
`PaintBall` writing the expected 32-byte block each time. The simulator
doesn't model the FPGA's video timing/blit, so whether the dbuf
actually eliminates tearing on screen can only be confirmed on real
hardware — that's the point of this demo.

### 2026-07-07 fix: `Move()` bouncing early (~y=128 instead of 176)

Reported after real-hardware testing: the ball in `bounce_sd81.bas`
bounced roughly mid-screen instead of reaching the bottom, as if it
had hit an early floor.

Root cause: `Move()`'s original version widened `bally (ubyte) + dy
(byte)` to an `integer` for the range check. The generated code
(`ld a,(_bally) / ld h,a / ld a,(_dy) / add a,h / ld l,a / add a,a /
sbc a,a / ld h,a`) computes the 8-bit sum correctly in the low byte,
then **sign-extends that 8-bit result based on its own bit 7** to fill
the high byte. That's correct if both operands were meant to be signed
bytes, but `bally` is genuinely unsigned (0-176) — `bally=126, dy=2`
gives an 8-bit sum of 128 ($80, bit 7 set), which gets sign-extended to
-128 instead of +128. `if newY < 0` then true firing the bounce 48
pixels early.

Fix: keep `Move()` entirely in `ubyte` (mod-256) arithmetic, matching
`bounce.asm`'s own `add a,b / cp 177` approach — never widen the
ubyte+byte sum to a signed integer at all, compare unsigned instead
(`if newY >= 177`). Verified by simulation: `bally` now climbs smoothly
through 128, 130, ... past the point where it used to bounce.

General lesson for this port: **`ubyte + byte` widened to `integer`
sign-extends the 8-bit sum's own bit 7, not the semantically correct
signed value** — safe when both operands are small/signed, wrong when
one operand (like a screen coordinate) is genuinely unsigned and can
exceed 127. Do that arithmetic in a type wide enough from the start
(assign the ubyte to an integer/uinteger variable *before* adding), or
stay in 8-bit space with an unsigned comparison if the range allows it,
as done here.

### 2026-07-14: RST $38 behaves like a real HALT instead of hanging forever

User request: interrupts stay disabled for the whole program (by
design), so RST $38/IM1 "should never be reached" — but if something
did reactivate them, the old `di`+`halt` handler locked the machine up
permanently. Changed it to wait for the next VSYNC pulse (port `$AF`,
bits 6-1 = pulse counter, reset on read) and `ret`, approximating what
a real Z80 HALT does (resume after the next interrupt) instead of
hanging.

**Found along the way: `src/lib/arch/zx81sd/runtime/vectors.asm` was
dead code, never `#include`d by anything.** The actual RST vector table
is emitted directly as Python-generated ASM text in
`backend/main.py::emit_prologue()` (`org $0038` / `di` / `halt`, etc.)
— a duplicate of what `vectors.asm` described, added in the same
original commit but apparently never wired together. First attempt at
this fix edited `vectors.asm` and got silently ignored (compiled
binaries kept the old `di`/`halt` bytes at $0038) until byte-inspecting
the actual output caught it. Fixed the real source in `main.py` instead
and deleted `vectors.asm` to remove the misleading duplicate — if
`vectors.asm` (or any other zx81sd runtime `.asm` file) needs editing
again, first grep for whether it's actually `#include`d/`#require`d by
anything, don't assume a file with a plausible name and location is
live.

Verified: compiled binary now has `DB AF E6 7E 28 FA C9` at `$0038`
(`in a,($AF)` / `and $7E` / `jr z,-6` / `ret`) instead of `F3 76`
(`di`/`halt`); simulated a stray RST $38 with a port callback that
returns "no pulse" 3 times then "pulse" — confirmed the loop reads the
port exactly 4 times (3 waits + the one that breaks it) before
falling through to `ret`.

**Also discussed and closed: returning to the ZX81 BASIC prompt after a
program ends**, instead of the permanent `di`/`halt` at
`__END_PROGRAM`. Not feasible, for two independent reasons:

1. **No software reset path exists in the FPGA at all** (confirmed by
   the hardware's author): `nRESET` in `SD81.v` is a plain input wire
   driven by the board's own reset circuit — nothing in the Z80-facing
   register set can pulse it. There is no port write or mapper page
   value that re-triggers the power-on sequence from software.
2. Even if there were, `tools/boot1.asm` remaps block 0 away from the
   ZX81's own ROM/RAM to run the compiled program, and `USAGE.md`'s own
   loader documentation notes the mapper's full-paging mode "doesn't go
   back to simple mode until the next reset" — a one-way transition by
   design. And the original BASIC session's own RAM (variables, display
   file, stack) has already been overwritten by the compiled program by
   the time it runs, so there's no state left to return *to* anyway.

Bottom line: the closest thing to "exit to BASIC" a zx81sd program can
offer is `RST 0` (restarts the *current* program, already wired in the
vector table above) — a genuine return to a ZX81 BASIC prompt requires
the physical reset. Not revisiting unless the hardware itself gains a
software-triggerable reset line.

## `array.asm` corrupted code on every multi-dimensional array access — RESOLVED (2026-07-22)

Found while porting a third-party game (ZXOilPanic, heavy user of 2D
arrays like `sprite(29,3)`, `down(4,1)`, etc.) to zx81sd. Caught live on
real hardware with EightyOne's debugger: a write breakpoint on the Z80
stack pointer's own descent showed a `PUSH DE` corrupting `FP_STKEND`
(`$8024`), which cascaded into the floating-point calculator operating
on garbage addresses, eventually executing screen/attribute memory as
code and crashing (`RST 8`, `RST 30`, or a wild jump into `$C000+`,
depending on what garbage byte the CPU happened to land on).

Root cause, once traced back far enough: `src/lib/arch/zx48k/runtime/
array/array.asm` (`__ARRAY`, the shared N-dimensional array indexing
routine used by **every** zxbasic program that declares a
multi-dimensional array) uses `LBOUND_PTR EQU 23698` — the real
Spectrum's `MEMBOT` system variable — as scratch storage for 4 pointer
pairs (8 bytes: `LBOUND_PTR`/`UBOUND_PTR`/`RET_ADDR`/`TMP_ARR_PTR`).
On a real Spectrum that's safe ROM-reserved RAM. On zx81sd, address
23698 ($5C92) falls **inside the program's own compiled code** (block 2,
$4000-$5FFF) instead of a real sysvar — every array access silently
corrupted a few bytes of code there. This is a **general zx81sd port
bug**, not specific to this game: any zx81sd program using
multi-dimensional arrays was at risk, it just hadn't been exercised
heavily enough by earlier examples/tests to surface (none of them used
2D+ arrays this intensively).

Fix: new `src/lib/arch/zx81sd/runtime/array/array.asm`, an override of
the shared file (Boriel's rule: the shared one stays untouched) with
the only change being `LBOUND_PTR EQU ARRAY_SCRATCH` instead of `EQU
23698` — `ARRAY_SCRATCH` is a new dedicated 8-byte sysvar
(`sysvars.asm`, `SYSVAR_BASE + $83`, right after `FP_MEM_AREA`, still
well within the $8000-$80FF sysvar block before the heap at $8100).

Verified by simulation: 1.2 billion T-states with a write-monitor on
both the old MEMBOT address (zero writes now) and the two known
hang-vector addresses (`$0008`/`$0009`, `$0030`/`$0031` — never
reached). Previously, with the same binary before this fix, the
program reliably crashed within a few hundred million T-states via one
of those two RST vectors.

## Same bug, two more places: `chr.asm` and `arith/divf.asm` — RESOLVED (2026-07-22)

The array.asm fix above turned out to be one instance of a **systemic
pattern** across the shared zx48k runtime: a project-wide grep for
`EQU 2[34]...` found roughly a dozen files that hardcode raw Spectrum
system-variable addresses as local scratch/temp storage, bypassing
`sysvars.asm` entirely (so zx81sd's own sysvars.asm override never
gets a chance to relocate them). Confirmed two more of these actually
firing while continuing to debug ZXOilPanic on real hardware after the
array.asm fix — the corruption just moved to a different address once
the binary's layout shifted:

- `runtime/chr.asm` (the `CHR$()` function, called 6 times per score
  update in this game) uses `TMP EQU 23629` (Spectrum's `DEST`) to
  stash the return address while calling `__MEM_ALLOC`. On zx81sd,
  23629 ($5C4D) landed inside `__DIVU32` (32-bit division) in the
  build being tested.
- `runtime/arith/divf.asm` (floating-point division, used by
  `score/66.0` in this game) uses `TMP EQU 23629` (same address as
  chr.asm) and `ERR_SP EQU 23613` to save/restore a stack recovery
  point around the division (a "longjmp" trick for divide-by-zero,
  matching the real Spectrum ROM's error-trapping convention). This
  code runs on **every** division, not just on error — worth noting
  that on zx81sd this recovery mechanism doesn't actually do anything
  useful anyway, since `__ERROR` does `DI`+`HALT` directly rather than
  restoring `SP` from `ERR_SP` to unwind — but it still unconditionally
  writes to both addresses every time regardless.

Fix, same pattern as array.asm: new `runtime/chr.asm` and
`runtime/arith/divf.asm` overrides, each with only the address changed
(`CHR_SCRATCH` at `$808B`, `DIVF_SCRATCH` — TMP+ERR_SP, 4 bytes — at
`$808D`, both in `sysvars.asm` after `ARRAY_SCRATCH`).

Verified by simulation with a corrected VSYNC-pulse mock (the earlier
simulations in this session had used an oversimplified port-toggle mock
that doesn't match the real bit-6-1 pulse-counter semantics `PAUSE`
expects, which risked mid-testing false "hangs"): monitored writes
across the **entire** program's address space (not just block 2) for
200 million T-states — zero unexpected corruption, versus reliably
corrupting code within a few hundred thousand T-states before these
two fixes.

**Not yet audited**: the same grep turned up further untouched
hardcodes in `runtime/arith/modf16.asm` (`TEMP EQU 23698`, same as
array.asm's old MEMBOT) and `runtime/break.asm`'s `PPC` — the former
isn't exercised by this particular game (no `MOD` operator used) so it
was left alone for now; a full systemic audit of every zx48k runtime
file for this pattern is worth doing separately at some point, this
session only fixed the ones actually observed corrupting a real
program.

## Stray EI in ported code corrupted arithmetic at random — RESOLVED

**Symptom (ZXOilPanic)**: `sprite(13,2)` — a plain 2D-array read —
returned -1 instead of 2072, but only when the game ran at full speed:
single-stepping in the debugger never reproduced it, the array's data
in RAM was verified intact (no writes ever hit it), and an isolated
test reading the same array/index worked perfectly. The wrong value
(-1) made the sprite blit read from `@sprites - 1`, painting garbage.

**Root cause**: the game's `tilexy` asm block ends with `EI` (and the
BeepFX engine's exit path too) — normal on the Spectrum, but zx81sd's
runtime runs with interrupts disabled at all times. After the first
`tilexy` call, interrupts stayed enabled, and the ZX81 fires IM1 INTs
continuously (A6 low during refresh), landing on `$0038`. Our
`RST38_WAIT` vector clobbered **A and flags** (`in a,($AF)` / `and`),
so any interrupted computation (e.g. `__ARRAY`'s offset arithmetic)
resumed with corrupted A/F. Classic heisenbug: stepping in EightyOne
doesn't deliver INTs the same way, so it vanished under the debugger.

**Fix (two layers)**:
1. Game side: `#ifndef __ZX81SD__` around both `EI`s (ported programs
   must never re-enable interrupts on zx81sd).
2. Runtime side (defense-in-depth, `backend/main.py`): the `$0038`
   vector now does `push af` / wait for VSYNC pulse / `pop af` / `ret`,
   so a stray INT costs only time instead of corrupting registers.

**Lesson**: when porting Spectrum code, grep for `\bei\b` and `\bhalt\b`
in every asm block. A heisenbug that disappears under single-stepping
on zx81sd should immediately suggest interrupts got re-enabled.
