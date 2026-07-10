# Usage: compiling, packaging and loading a program on zx81sd

## 1. Compile

From the root of this repository:

```
python -m src.zxbc.zxbc <source.bas> --arch zx81sd -o <output.bin> -M <output.map>
```

- `--arch zx81sd` selects this architecture's backend and overrides
  (see [../README.md](../README.md) — the port's golden rule).
- `-M <output.map>` is optional but strongly recommended: it generates
  the symbol map (address of every ASM/BASIC label), essential for
  debugging with an emulator or simulating the binary (see
  [MAP.md](MAP.md) for examples of Python simulation harnesses).
- Examples transcribed from classic Sinclair BASIC (1-based
  arrays/strings) usually also need `--string-base 1 --array-base 1`
  (see [BASIC_CHANGES.md](BASIC_CHANGES.md), `comecoquitos.bas` example).

There's also `python zxbc.py --arch zx81sd -f bin -o <output.bin> <source.bas>`
(the traditional entry-point script); both forms are equivalent.

## 2. Package for the ZX81

The binary produced by the compiler is a flat image of up to 48KB
(blocks 0-5 of the SD81 mapper). The ZX81 can only load, in one go,
whatever fits in its own visible RAM, so that binary has to be split
into 8KB pages and a BASIC loader generated that feeds them one by one
into the SD81 Booster card, remapping the memory mapper between pages.

That's what [`../tools/split_sd81.py`](../tools/split_sd81.py) does:

```
python src/arch/zx81sd/tools/split_sd81.py <output.bin> [PREFIX]
```

- `PREFIX` (optional) is the base name for the output files, in the
  ZX81 charset (letters, digits, no underscore). If omitted, it's
  derived from the input `.bin` file name.
- It generates:
  - `<PREFIX>P8.BIN`, `<PREFIX>P9.BIN`, ... — one per 8KB of the binary
    (SD81 page 8 = block 0, page 9 = block 1, etc.)
  - `<input>_loader.txt` — the loader's BASIC listing in plain text
    (for reading/debugging).
  - `<PREFIX>.P` — the same loader, already tokenized, ready to load
    and run on the ZX81 from the SD card.

The generated loader uses `LOAD THEN CLEAR`, `LOAD *MAP` and
`LOAD FAST ... CODE`, extensions provided by the SD81 Booster firmware
(they don't exist in the original ZX81 ROM). It does the following, in
order:

1. Reserves memory (`CLEAR`) and loads `BOOT1.BIN` (the stage 1 loader,
   fixed for every program — source in
   [`../tools/boot1.asm`](../tools/boot1.asm), already-assembled binary
   in [`../tools/boot1.bin`](../tools/boot1.bin)).
2. For each page of the binary: maps block 7 to that physical page
   (`LOAD *MAP 7,<n>`) and dumps the data there (`LOAD FAST ... CODE
   57344`, block 7's window at `$E000`).
3. When done, leaves the mapper in "full page" mode (`LOAD *MAP
   7,63`) — from this point on the mapper doesn't go back to simple
   mode until the next reset — and jumps to `BOOT1.BIN` (`RAND USR
   24576`), which does the final mapping of blocks 0-5 and starts the
   program.

## 3. Copy to the SD card

Copy to the SD card, alongside the rest of your collection:

- `BOOT1.BIN` (only once, it's the same for every program)
- All the `<PREFIX>P<n>.BIN` files for the program
- `<PREFIX>.P`

Then on the ZX81 (or in EightyOne pointing at the SD image): load and
run it with `LOAD FAST "<PREFIX>"` — no need to select anything
afterwards, it runs straight from there.

## 4. Debugging without hardware: simulation with Python

To diagnose hangs, HALTs or incorrect results without having to test on
the emulator or real hardware every time, this port's development has
used Python's `z80` package (`pip install z80`) to simulate the flat
binary directly. The full methodology (including one important trap:
the simulator's RAM starts at zero, which can hide uninitialized-memory
bugs that do show up on real hardware) is documented in
[MAP.md](MAP.md) — the "Heap at $8100 + EightyOne tape traps" section
and the methodology notes on the MSFS/maskedsprites bug.
