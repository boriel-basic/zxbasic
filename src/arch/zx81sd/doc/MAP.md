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
