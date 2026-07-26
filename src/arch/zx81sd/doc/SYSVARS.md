# zx81sd system variables — equivalence table with the Spectrum ROM

zx81sd has no ROM: every "system variable" the shared `zx48k/runtime/`
code expects at a fixed Spectrum address is instead a real RAM
variable allocated by zx81sd at `SYSVAR_BASE` (`$8000`) upwards, laid
out in [`src/lib/arch/zx81sd/runtime/sysvars.asm`](../../../lib/arch/zx81sd/runtime/sysvars.asm).
This table is the single place that maps each one back to the
Spectrum ROM address it substitutes for, so a search for a Spectrum
address (`23698`, `$5C7B`, etc.) found while porting code has
somewhere to land.

## Quick reference (the things every port hits first)

| Concept | Spectrum | zx81sd | Source |
|---------|:--------:|:------:|--------|
| Pixel screen base | `$4000` (16384) | `$C000` (49152) | `SCREEN_ADDR`, see below |
| Attribute screen base | `$5800` (22528) | `$D800` (55296) | `SCREEN_ATTR_ADDR`, see below |
| ULA port (border color, `OUT`) | `$FE` (254) | `$FB` (251) | `border.asm` — `SD81_ULA_PORT` |
| ULA port (beeper, `OUT`) | `$FE` (254), bit 4 | `$FB` (251), bits 4-3 | `beep.asm` — same port as border, see note below |
| AY register-latch port (`OUT`) | `$FFFD` (65533, Spectrum 128) | `$CF` (207) | `stdlib/play.bas` — `_PLAY_WRITE_TO_REGISTER` |
| AY data port (`OUT`) | `$BFFD` (49149, Spectrum 128) | `$0F` (15) | ditto — SD81 Booster's ZonX-81 AY interface |

The ULA port note: on the real Spectrum, border color (bits 2-0) and
beeper (bit 4) share the **same** write-only port `$FE`, so any code
poking a raw byte to it needs to preserve the other's bits. zx81sd's
SD81 Booster (Superfast HiRes Spectrum mode) emulates this exact
sharing at `$FB` instead, bits laid out the same way (2-0 border,
4-3 beeper) — `border.asm`/`beep.asm` keep a shadow byte
(`__ZX81SD_ULA_SHADOW`) for the same reason the real ROM effectively
needs one. **If a ported program pokes the ULA port directly instead
of using `BORDER`/`BEEP`, change `$FE`→`$FB` (or `254`→`251`) and route
it through the shadow byte, not a raw `OUT`** — see
[PORTING_GUIDE.md](PORTING_GUIDE.md) step 3.

Note: `$FE` is *also* a real, working port on zx81sd — but for the
**native ZX81 keyboard matrix** (`break.asm` reads it directly for the
BREAK key), not the Spectrum ULA. A Spectrum program that does its own
manual keyboard scanning via `IN A,($FE)` (bypassing `INKEY$`) will
read a **different** row/bit layout on zx81sd's actual hardware — that
port number being valid on both machines for unrelated purposes is a
coincidence worth being aware of, not a compatibility shortcut.

The AY port note: besides the port numbers themselves, the AY chip's
**clock speed differs too** — the SD81 Booster's FPGA clocks its AY at
1.625 MHz (3.25 MHz / 2) versus the Spectrum 128's 1.7734 MHz. A
program that pokes raw note-divider values into AY registers 0-13
(rather than going through `PLAY`/`SetChipTone` etc.) needs those
dividers recalculated for the new clock (`divider = round(1625000 /
16 / frequency)`), or every note will play at the wrong pitch — see
`stdlib/play.bas`'s `_Play_NoteDividers` table for the reference
conversion, and the closed `sd81-sound-calibration` project memory for
how this was measured and confirmed on real hardware (BEEP runs off a
separate, unrelated 3.25 MHz clock — don't confuse the two chips'
clocks when converting timings).

See [PRECAUTIONS.md](PRECAUTIONS.md) section 1 for *why* this matters
(zx81sd has no ROM at all — a numeric literal like `23675` is never
valid on zx81sd, it lands inside the program's own compiled code) and
section 8 for how to safely reference these from a new library file
(`#require "sysvars.asm"`, never `#include once`).

## Main block (mirrors `zx48k/runtime/sysvars.asm`)

These are the ones the shared zx48k runtime/stdlib code accesses **by
symbolic name** (`CHARS`, `UDG`, `ATTR_P`...) — since the symbol
resolves against whichever `sysvars.asm` got linked in, zx81sd's own
definitions satisfy them automatically, no override file needed.

| Symbol      | Spectrum ROM addr | zx81sd addr | Size | Purpose |
|-------------|:-----------------:|:-----------:|:----:|---------|
| `CHARS`     | 23606 (`$5C36`)   | `$8000`     | 2B (DW) | Pointer to charset (8×8) |
| `UDG`       | 23675 (`$5C7B`)   | `$8002`     | 2B (DW) | Pointer to UDG charset |
| `COORDS`    | 23677 (`$5C7D`)   | `$8004`     | 2B (DW) | Last `PLOT` coordinate (X,Y) |
| `FLAGS2`    | 23681 (`$5C81`)   | `$8006`     | 1B   | Screen flags (OVER/INVERSE/etc.) |
| `ECHO_E`    | 23682 (`$5C82`)   | `$8007`     | 1B   | (reserved, unused by zx81sd) |
| `DFCC`      | 23684 (`$5C84`)   | `$8008`     | 2B (DW) | Next screen (bitmap) address for `PRINT` |
| `DFCCL`     | 23686 (`$5C86`)   | `$800A`     | 2B (DW) | Next screen-attribute address for `PRINT` |
| `S_POSN`    | 23688 (`$5C88`)   | `$800C`     | 2B   | Cursor position (H=row, L=col) |
| `ATTR_P`    | 23693 (`$5C8D`)   | `$800E`     | 1B   | Permanent attribute (INK/PAPER/...) |
| `MASK_P`    | 23694 (`$5C8E`)   | `$800F`     | 1B   | Permanent mask (implicit `ATTR_P+1`, not a separate EQU on either side) |
| `ATTR_T`    | 23695 (`$5C8F`)   | `$8010`     | 1B   | Temporary attribute |
| `MASK_T`    | 23696 (`$5C90`)   | `$8011`     | 1B   | Temporary mask (implicit `ATTR_T+1`) |
| `P_FLAG`    | 23697 (`$5C91`)   | `$8012`     | 1B   | Print flags (permanent OVER/INVERSE) |
| `MEM0`/`MEMBOT` | 23698 (`$5C92`) | `$8013`   | 5B   | Temp buffer used by ROM char routines. **Same physical Spectrum address as `MEMBOT`** below — the real ROM reuses this scratch for two unrelated purposes depending on context; zx81sd keeps them as two clearly-named, non-overlapping zones instead (`MEM0` here, `ARRAY_SCRATCH` separately) |
| `TV_FLAG`   | 23612 (`$5C3C`)   | `$8018`     | 1B   | Output-to-screen control flags |

Not in the shared file, zx81sd-only additions used by the same
symbolic-name mechanism:

| Symbol      | Nearest Spectrum concept | zx81sd addr | Size | Notes |
|-------------|--------------------------|:-----------:|:----:|-------|
| `ERR_NR`    | `ERR_NR` — 23610 (`$5C3A`) | `$8019`   | 1B   | Error code (-1 = no error) |
| `FRAMES`    | `FRAMES` — 23672 (`$5C58`), 3B on real ROM | `$801A` | 2B (DW) | Software VSYNC frame counter — zx81sd has no hardware interrupt to auto-increment it (see `VSYNC_TICK`/`PAUSE`), only needs 16 bits |
| `RANDOM_SEED_LOW` | `SEED` low word — 23670 (`$5C76`) | `$801C` | 2B (DW) | RNG seed |
| `SCREEN_ADDR` | not a ROM sysvar — zxbasic's own indirection variable (`zx48k/runtime/sysvars.asm`: `DW 16384`) | `$801E` | 2B (DW) | Framebuffer pointer, init `$C000` (vs `16384` on Spectrum) |
| `SCREEN_ATTR_ADDR` | ditto (`DW 22528`) | `$8020` | 2B (DW) | Attribute pointer, init `$D800` (vs `22528`) |

## Floating-point calculator (`fp_calc.asm`)

Real Spectrum ROM sysvars, but zx81sd points them at a **fixed**
buffer instead of the ROM's dynamically-growing area (there's no
"free memory between program and stack" concept here):

| Symbol        | Spectrum ROM addr  | zx81sd addr | Size | Notes |
|---------------|:-------------------:|:-----------:|:----:|-------|
| `FP_STKBOT`   | `STKBOT` — 23651 (`$5C63`) | `$8022` | 2B (DW) | Base of the FP number stack |
| `FP_STKEND`   | `STKEND` — 23653 (`$5C65`) | `$8024` | 2B (DW) | Next free slot in the FP stack |
| `FP_BREG`     | `BREG` — 23655 (`$5C67`)   | `$8026` | 1B | Literal currently being parsed |
| `FP_MEM`      | `MEM` — 23656 (`$5C68`)    | `$8027` | 2B (DW) | Pointer to the MEM area (6×5B cells) |
| `FP_CALC_STACK` | n/a (dynamic on real ROM) | `$8029` | 60B | Fixed FP number stack (12 numbers max) |
| `FP_MEM_AREA` | n/a (dynamic on real ROM)  | `$8065` | 30B | Fixed MEM area (6×5B cells) |

`FP_BREG` **must** sit immediately after `FP_STKEND` — the CALCULATE
engine (`ENT-TABLE`/`fp-calc-2`/`dec-jr-nz`) exploits the real ROM's
memory contiguity (`STKEND_hi` immediately followed by `BREG`) to load
both with a single `LD BC,(FP_STKEND+1)`. Don't reorder these two.

## Hardcoded-address scratch fixes (not exposed by symbolic name)

These shared `zx48k/runtime/` files bypass `sysvars.asm` entirely and
hardcode a raw Spectrum address as scratch storage — on zx81sd that
address lands inside the program's own compiled code (block 2,
`$4000-$5FFF`) instead of safe RAM, silently corrupting it. Each one
needed its own zx81sd **override file** (only the address changed, see
[MAP.md](MAP.md) for the full incident writeups) rather than a plain
`sysvars.asm` entry, since the shared code never references them by a
name `sysvars.asm` could satisfy:

| Symbol (shared file's own name) | Spectrum addr | zx81sd override | zx81sd addr |
|----------------------------------|:-------------:|------------------|:-----------:|
| `LBOUND_PTR`/`UBOUND_PTR`/`RET_ADDR`/`TMP_ARR_PTR` (`array.asm`, aliases `MEMBOT`) | 23698 (`$5C92`) | `runtime/array/array.asm` | `ARRAY_SCRATCH` = `$8083` (8B) |
| `TMP` (`chr.asm`, alias `DEST`) | 23629 (`$5C4D`) | `runtime/chr.asm` | `CHR_SCRATCH` = `$808B` (2B) |
| `TMP`/`ERR_SP` (`arith/divf.asm`, aliases `DEST`/`ERR_SP`) | 23629 (`$5C4D`) / 23613 (`$5C3D`) | `runtime/arith/divf.asm` | `DIVF_SCRATCH` = `$808D` (4B: TMP 2B + ERR_SP 2B) |

Total sysvar block size: `$91` bytes (`$8000`-`$8090`), well before the
heap start at `$8100`.

**Not yet audited / no override exists** (same antipattern, not yet
observed corrupting a real program — see `oilpanic-portability.md`
project memory and `MAP.md` for the hunting method if one of these
ever bites):

| Symbol | Spectrum addr | Shared file | Only triggered by |
|--------|:-------------:|-------------|--------------------|
| `TEMP` (alias `MEMBOT`) | 23698 (`$5C92`) | `runtime/arith/modf16.asm` | the `MOD` operator |

A quick grep for the pattern across all of `zx48k/runtime`:
`EQU 2[34][0-9][0-9][0-9]` — anything that turns up and *doesn't*
already have a zx81sd override (see next section) is a candidate.

## Shared files with hardcoded Spectrum addresses that zx81sd already
## bypasses entirely (full rewrite, not just an address patch)

These also matched the grep above, but zx81sd ships a **complete**
override with no numeric Spectrum address left at all (not just a
scratch-address swap) — listed here so they're not mistaken for
unaudited risks:

| Shared file | Hardcoded Spectrum addr(s) | zx81sd override |
|-------------|------------------------------|------------------|
| `runtime/break.asm` (`PPC`) | 23621 (`$5C45`) | `zx81sd/runtime/break.asm` |
| `runtime/load.asm` (`BREG` alias) | 23655 (`$5C67`) | `zx81sd/runtime/load.asm` |
| `runtime/save.asm` (`MEMBOT` alias) | 23698 (`$5C92`) | `zx81sd/runtime/save.asm` |
| `runtime/val.asm` (`STKBOT`/`ERR_SP`/`CH_ADD`) | 23651/23613/23645 | `zx81sd/runtime/val.asm` |
| `runtime/random.asm` (`RANDOM_SEED_LOW`) | 23670 (`$5C76`) | `zx81sd/runtime/random.asm` |
