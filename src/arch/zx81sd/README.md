# `zx81sd` architecture: ZX81 + SD81 Booster

`zx81sd` is an architecture for this compiler targeting a **real ZX81
with the [SD81 Booster](https://www.sd81.eu/) card** (an interface that
adds a Spectrum-like screen, AY/beeper sound, a paged memory mapper and
SD card access).

All code specific to this architecture lives exclusively under:

```
src/arch/zx81sd/            (compiler backend, this documentation,
                             and the packaging tools under tools/)
src/lib/arch/zx81sd/        (ASM runtime + BASIC stdlib)
```

## The port's golden rule

This compiler is shared by every architecture (zx48k, zx128k,
zxnext...). **The zx81sd port never modifies the shared frontend or
stdlib/runtime.** The `#include`/`#require` resolution mechanism looks
first in `src/lib/arch/zx81sd/`, and if it doesn't find the file it
automatically falls back to `src/lib/arch/zx48k/` (the shared one).
That's why many zx81sd overrides are full copies of the zx48k version
with just a few lines changed: the whole file has to be copied, not
patched — a partial override simply doesn't exist as a concept here.

Before touching anything outside `zx81sd/`, stop: there's probably a
way to solve it with an override.

## Port status

Functionally complete since 2026-07-02: FP (our own RST $28), graphics
(PLOT/DRAW/arcs/CIRCLE), sound (BEEP and PLAY over the AY ZonX and the
beeper), keyboard (INKEY$/INPUT over the ZX81's physical keyboard),
joystick, the complete MCU library (files, RTC/BAT, voice, memory
mapper...) and LOAD/SAVE/VERIFY...CODE against SD.

Pending / not audited, remaining screen utilities in the shared stdlib:

- `winscroll.bas`: **confirmed working on real hardware** — no ROM
  dependency, no override needed (like `scroll.bas` before its fix, or
  `4inarow.bas`). No source changes needed either
  (`examples/winscroll.bas` as-is).
- `putchars.bas`: **confirmed working on real hardware** — no ROM
  dependency, no override needed
  (`examples/sd81/putcharstile.bas`).
- `puttile.bas`: **confirmed working on real hardware** — needed a
  zx81sd override for hardcoded screen/attribute base constants, same
  bug class as `print42.bas`/`print64.bas` (fixed the same way,
  self-modifying code patched at runtime).
- `screen.bas`: **does depend on the ROM** (`$2538`/`$5C65`/`$19E8`,
  fixed Spectrum routines and sysvars to read back a screen character)
  — will need a real override, not just an audit.
- `print42.bas`/`print64.bas`: **ported and confirmed working on real
  hardware** — fixed sysvars → zx81sd equivalents, and the screen/
  attribute base constants are patched at runtime (self-modifying
  code) instead of being fixed.

See [doc/BASIC_CHANGES.md](doc/BASIC_CHANGES.md) for the general
pattern behind this kind of fix. The `maskedsprites.bas`/MSFS port
(masked sprites over the memory mapper) is also in progress, still not
fully working.

## Documentation

- **[doc/USAGE.md](doc/USAGE.md)** — how to compile a program, package
  it for the ZX81 and load it from the SD card.
- **[doc/PRECAUTIONS.md](doc/PRECAUTIONS.md)** — what to keep in mind
  when writing or porting software for this architecture (memory map,
  sysvars, keyboard, things that do NOT exist here even though they do
  on a Spectrum).
- **[doc/BASIC_CHANGES.md](doc/BASIC_CHANGES.md)** — what BASIC source
  changes were needed to port each official example in `examples/`
  (with the why for each one). Mandatory starting point before porting
  a new example: it's almost always one of the patterns already
  cataloged there.
- **[doc/MAP.md](doc/MAP.md)** — detailed technical log of every bug
  found and fixed during the port (ASM runtime, not BASIC sources),
  with the investigation trace for each one. The document to check
  when something fails at runtime in a way that resembles an
  already-solved bug.

## Examples

The example programs already adapted/tested for this architecture are
in [`examples/sd81/`](../../../examples/sd81/) (alongside the rest of
the compiler's `examples/`). The detail of what had to be changed in
each one, and why, is in
[doc/BASIC_CHANGES.md](doc/BASIC_CHANGES.md).

## Packaging tools

[`tools/split_sd81.py`](tools/split_sd81.py) splits the flat binary
produced by the compiler into 8KB pages and generates the `.p` loader
for the ZX81; [`tools/zx81_p_loader.py`](tools/zx81_p_loader.py) is the
BASIC tokenizer it uses to generate it; [`tools/boot1.asm`](tools/boot1.asm)/
[`tools/boot1.bin`](tools/boot1.bin) are the second-stage loader (stage
1), fixed for every program. See [doc/USAGE.md](doc/USAGE.md) for the
full compile → package → load flow. The wider set of debugging/
diagnostic sources used during the port's development (not tools, just
one-off tests) lives in a private companion repository, not this one.

## Related repositories

- **[SD81 Booster](https://codeberg.org/Retrostuff/SD81-Booster)** —
  the hardware/firmware for the interface this port targets.
- **[EightyOne Cross-platform](https://codeberg.org/wilco2009/EightyOne-CrossPlatform)** —
  the emulator used during development to test without real hardware.
- **[CPM_SD81](https://codeberg.org/wilco2009/CPM_SD81)** — CP/M on the
  SD81 Booster.
