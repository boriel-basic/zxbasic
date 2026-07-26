# Step-by-step guide: porting a Spectrum ZX BASIC program to zx81sd

This is a checklist, not a tutorial — each step links to the doc that
has the full detail. Work through it roughly in order; most of it only
matters if the specific pattern shows up in the program you're
porting. Everything here was distilled from real ports (official
`examples/`, and a full third-party game, ZXOilPanic) that hit one or
more of these in practice — see [MAP.md](MAP.md) for the investigation
traces if you want the "why" behind any of them.

## 0. The one rule that makes everything else optional

**Keep the exact same `.bas` source compiling for both `zx48k` and
`zx81sd`.** Don't fork the file, don't overwrite Spectrum-targeting
code unconditionally — wrap every zx81sd-specific change:

```basic
#ifdef __ZX81SD__
    ' zx81sd-specific code
#else
    ' original Spectrum code
#endif
```

This works identically inside `asm ... end asm` blocks (the
preprocessor runs at the text level, before the BASIC/ASM split).
Compile for each target with:

```
python zxbc.py <source.bas> --arch=zx48k -o out_spectrum.bin
python zxbc.py <source.bas> --arch=zx81sd -D __ZX81SD__ -o out_zx81sd.bin -M out_zx81sd.map
```

(or the one-shot [`build_sd81.py`](../tools/build_sd81.py) for the
zx81sd side, see step 8). `zxbasic` never defines `__ZX81SD__`
automatically — you always pass it by hand with `-D`.

## 1. There is no ROM: hunt down hardcoded Spectrum addresses

Grep the source (and any library `.bas`/`.asm` it pulls in) for:
- Raw numeric `POKE`/`PEEK`/`CALL` addresses (4-5 digit decimals, or
  hex like `$5C..`/`$22..`).
- Anything that looks like a Spectrum ROM sysvar name in a comment
  (`UDG`, `COORDS`, `BORDCR`, `FRAMES`, `ATTR_P`...).

Every one of these needs translating via the **full equivalence
table** in [SYSVARS.md](SYSVARS.md) (Spectrum address ↔ zx81sd
address, for every sysvar zx81sd exposes). A few you'll hit almost
immediately even in simple programs:

- **Screen/attribute base address**: Spectrum `$4000`/`$5800` →
  zx81sd `$C000`/`$D800`. Common in raw `LDIR`/`PEEK`/`POKE` screen
  code that doesn't go through `SCREEN_ADDR`/`SCREEN_ATTR_ADDR`.
- **ULA port** (border color / beeper, `OUT`/`IN` on `$FE`/254):
  zx81sd emulates the same border+beeper bit layout at `$FB`/251
  instead. Full detail and the keyboard-port caveat in SYSVARS.md's
  "Quick reference" table — **don't** just s/254/251/ on a raw `OUT`,
  route it through the shadow-byte mechanism `BORDER`/`BEEP` already
  use, or you'll clobber whichever of border/beeper you didn't intend
  to touch.
- **AY sound chip ports** (Spectrum 128's `$FFFD`/`$BFFD` register
  latch/data) → zx81sd's SD81 Booster ZonX-81 interface at `$CF`/`$0F`
  instead — see `stdlib/play.bas`'s `_PLAY_WRITE_TO_REGISTER` for the
  reference. If the program pokes raw note dividers into AY registers
  directly (not through `PLAY`), also recompute them for the SD81's
  1.625 MHz AY clock (vs the Spectrum 128's 1.7734 MHz) — same
  SYSVARS.md section has the formula.

See [PRECAUTIONS.md](PRECAUTIONS.md) section 1 for the full rationale
and [BASIC_CHANGES.md](BASIC_CHANGES.md) for a line-by-line catalog of
every case already found in the official examples.

## 2. Never `EI`, never wait on `HALT`

zx81sd runs the **entire program** with interrupts disabled. Grep
every ASM block (inline `asm...end asm` and any hand-written `.asm`
library) for `\bei\b` and `\bhalt\b`:

- `EI` (with or without a following `HALT`) is dangerous — see
  [PRECAUTIONS.md](PRECAUTIONS.md) section 4 for exactly how bad
  (a real, hours-long heisenbug came from a single stray `EI` at the
  end of a sprite-blit routine, corrupting unrelated array reads
  later on).
- A `HALT`-based wait for the Spectrum's 50Hz interrupt never wakes
  up on zx81sd. Replace it with `Pause n` (BASIC) or `call
  .core.VSYNC_TICK` (ASM) — see PRECAUTIONS.md section 4 for the
  exact substitution and namespace-prefix gotcha.

**Diagnostic tell**: if a bug reliably disappears while single-stepping
in the debugger but reproduces at full run speed, suspect a stray `EI`
first, before anything else.

## 3. Register contracts and ASM label namespaces

If the program includes hand-written `.asm` that calls into runtime
routines directly (not just through BASIC statements), check
[PRECAUTIONS.md](PRECAUTIONS.md) sections 2 and 5: some routines have
non-negotiable register contracts (a replaced ROM routine must
preserve exactly what the original did), and zx81sd's namespace
mangling means a bare label reference from inside an `asm` block that
isn't already inside `push namespace core` needs the full `.core.`
prefix or you'll get `Undefined GLOBAL label`.

## 4. The keyboard is the ZX81's, not the Spectrum's

Any code that reads the keyboard by hand (not through `INKEY$`/
`INPUT`) via raw port I/O needs rework — the ZX81's keyboard matrix
layout is different from the Spectrum's, even where a port number
happens to coincide (see SYSVARS.md's ULA-port note). Full detail in
[PRECAUTIONS.md](PRECAUTIONS.md) section 3. Also remember: **the ZX81
keyboard has no shift-driven case distinction** — `SHIFT`+letter
produces a symbol, not uppercase, a common surprise when porting a
game that expects to read letter case directly (see
`zx81sd-keyboard-case` project memory if you're the original author
of this port — not a zxbasic-level fact, a physical hardware one).

## 5. `zxbasm` binary literal syntax

If the program has hand-written `.asm` using the trailing-`b` Pasmo/
Zilog binary literal convention (`10110010b`), it won't assemble —
`zxbasm` only accepts the leading form: `%10110010` or `0b10110010`.
Convert with a straightforward `sed`/regex pass before anything else,
it's a pure syntax issue with no semantic risk.

## 6. Dead-code elimination and `@function` references

If a subroutine or array is only ever referenced via its **address**
(`@myFunction`, `@myArray`) from inside another function's body — never
called directly, and never referenced from global/top-level code —
zxbasic's dead-code eliminator can fail to see it as "used" and strips
it, causing an `Undefined GLOBAL label` at link time (a real gap: the
optimizer's call-graph walker tracks `CALL`/`FUNCCALL` nodes, not
`ADDRESS` nodes, and address-of-inside-a-function-body is a separate
code path that isn't marked as "accessed"). Workaround: a throwaway
address-of reference at **global** scope keeps it alive:

```basic
' Compiler dead-code-elimination gap: @sprites is only ever taken from
' inside a function body, which isn't enough to mark it as used.
dim __keep_sprites as uinteger: __keep_sprites = @sprites
```

If you're banking a large data table (sprites, a level map...) into
block 7 to fit under the `$8000` budget (step 8) by wrapping a `sub`'s
`asm` body in a manual `ORG $E000`/restore, `@name` stops pointing at
the relocated data entirely (a different, related gap — see
[PRECAUTIONS.md](PRECAUTIONS.md) section 9) — you'll need both this
dead-code workaround *and* to stop using `@name` as an address.

## 7. Sysvar scratch bugs already fixed in the runtime — no action needed

Several shared `zx48k/runtime/` files historically hardcoded a raw
Spectrum sysvar address as scratch storage (bypassing `sysvars.asm`
entirely) — on zx81sd that address lands inside the program's own
compiled code, corrupting it. `array.asm` (multi-dimensional array
reads), `chr.asm` (`CHR$()`), and `arith/divf.asm` (floating-point
division) all had this bug and are **already fixed** with zx81sd
overrides — nothing to do here, just don't be surprised if you find
the override files while reading the runtime. `arith/modf16.asm`
(the `MOD` operator) has the same pattern and is **not yet fixed**
(not triggered by any program so far) — if a program using `MOD`
shows array-adjacent corruption, this is the first suspect. Full list
and the exact addresses in [SYSVARS.md](SYSVARS.md)'s hardcoded-scratch
tables.

## 8. Compile, package, and copy to the right place

```
python src/arch/zx81sd/tools/build_sd81.py <source.bas> [PREFIX] --copy-to <SD folder>
```

Does the compile (with `-D __ZX81SD__` and `-M` for the symbol map)
and the SD81 page-splitting + `.P`-loader generation in one command.
**Get `--copy-to` right, or point it at the emulator/hardware's real
SD folder by hand afterwards** — a stale package the emulator wasn't
actually reading was itself the cause of a multi-hour false-alarm
debugging session once, see [USAGE.md](USAGE.md) section 3b. If you
only need a fresh `.map` without repackaging (e.g. after hand-editing
the generated `.asm`), see `gen_map.py` in the same section.

## 9. Test and debug

- Simulating with Python's `z80` package before touching real
  hardware/emulator catches a lot, but has real limits: an
  oversimplified VSYNC-port mock can get a program stuck early, and a
  bug that depends on genuine interrupt timing (step 2) **cannot** be
  reproduced by a simulator that never delivers interrupts in the
  first place. See [MAP.md](MAP.md) and USAGE.md section 4 for the
  methodology and its known traps.
- Live debugging in EightyOne's Debug Window: execution breakpoints
  with hit-counts (`EXE=$addr`), write breakpoints (`WR=$addr`), and
  the Memory viewer (cross-referenced against the `.map` file) are the
  main tools — see MAP.md for worked examples of narrowing down a bug
  this way, including how to avoid re-triggering on the wrong call
  when many call sites share the same target address.
- **`.map` must match the binary actually loaded.** Regenerate it on
  every rebuild (`build_sd81.py`/`gen_map.py` both do); a mismatched
  `.map` gives confidently-wrong addresses that waste debugging time.

## See also

- [PRECAUTIONS.md](PRECAUTIONS.md) — the detailed rationale behind
  steps 1-4, one section each.
- [SYSVARS.md](SYSVARS.md) — full Spectrum ↔ zx81sd sysvar and I/O
  port equivalence table.
- [BASIC_CHANGES.md](BASIC_CHANGES.md) — catalog of source changes
  already needed in official examples.
- [USAGE.md](USAGE.md) — compiling, packaging, and simulating in
  detail.
- [MAP.md](MAP.md) — full technical log, bug by bug, with the
  investigation traces (the primary source almost every step above
  was distilled from).
