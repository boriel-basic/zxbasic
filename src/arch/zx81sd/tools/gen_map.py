#!/usr/bin/env python3
"""
gen_map.py — regenerate a zx81sd .map symbol file from BASIC source via
the intermediate .asm stage, instead of compiling straight to .bin.

Two-stage pipeline (this is what zxbc.py does internally in one step
when given -f bin -M map; this script exposes the split explicitly):
  1. zxbc.py --arch=zx81sd -D __ZX81SD__ -f asm -o <base>.asm
     (BASIC -> assembly, kept around for inspection/hand-editing)
  2. zxbasm.py -M <base>.map -o <base>.bin <base>.asm
     (assembly -> binary + .map; zxbasm always needs *some* output
     format, so a .bin comes out too as a byproduct)

Useful when the .asm is being hand-inspected or edited between steps
(a common retro workflow) and only a fresh, consistent .map is needed
to match it — skips split_sd81.py's page-splitting / .P-tokenizing
step entirely, since a plain zxbc.py -f bin -M compile already covers
the common "just rebuild everything" case (see build_sd81.py).

Usage:
  python gen_map.py <source.bas> [output_base] [-O LEVEL] [-D MACRO ...]
                     [--keep-asm] [zxbc.py extra args...]

  output_base defaults to the source file's name (without extension).
  --keep-asm: don't delete the intermediate .asm afterwards (kept by
  default anyway — flag exists only for symmetry/clarity, see below).

Example:
  python gen_map.py C:/ClaudeCode/ZXOilPanic/oilpanic.bas oilpanic
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
ZXBASIC_ROOT = TOOLS_DIR.parents[3]  # tools -> zx81sd -> arch -> src -> <zxbasic root>
ZXBC = ZXBASIC_ROOT / "zxbc.py"
ZXBASM = ZXBASIC_ROOT / "zxbasm.py"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("source", help="BASIC source file (.bas)")
    ap.add_argument(
        "output_base", nargs="?", help="Output base name (default: source file name)"
    )
    ap.add_argument("-O", "--optimize", default="2", help="zxbc.py optimization level (default 2)")
    ap.add_argument(
        "-D",
        "--define",
        action="append",
        default=[],
        metavar="MACRO",
        help="Extra -D macro for zxbc.py (repeatable). __ZX81SD__ is always defined.",
    )
    ap.add_argument(
        "--keep-asm",
        action="store_true",
        help="No-op (the .asm is always kept) — accepted for clarity/symmetry only.",
    )
    args, extra = ap.parse_known_args()

    if not ZXBC.is_file():
        sys.exit(f"Error: zxbc.py not found at {ZXBC} (unexpected repo layout)")
    if not ZXBASM.is_file():
        sys.exit(f"Error: zxbasm.py not found at {ZXBASM} (unexpected repo layout)")

    source = Path(args.source).resolve()
    if not source.is_file():
        sys.exit(f"Error: source file not found: {source}")

    base = args.output_base or source.stem
    workdir = source.parent
    asm_path = workdir / f"{base}.asm"
    bin_path = workdir / f"{base}.bin"
    map_path = workdir / f"{base}.map"

    zxbc_cmd = [
        sys.executable,
        str(ZXBC),
        str(source),
        "--arch=zx81sd",
        "-O",
        args.optimize,
        "-f",
        "asm",
        "-o",
        str(asm_path),
    ]
    for d in ["__ZX81SD__"] + args.define:
        zxbc_cmd += ["-D", d]
    zxbc_cmd += extra

    print("== zxbc.py (BASIC -> asm) ==")
    print(" ".join(zxbc_cmd))
    subprocess.run(zxbc_cmd, check=True)

    zxbasm_cmd = [
        sys.executable,
        str(ZXBASM),
        str(asm_path),
        "-o",
        str(bin_path),
        "-M",
        str(map_path),
    ]

    # zxbasm has no --arch/--include-path flag at all (unlike zxbc.py), so
    # it never learns zx81sd's architecture-specific include search path.
    # A bare INCBIN filename (e.g. "specfont.bin", pulled in by
    # charset.asm) is resolved with local_first=True against the .asm
    # file's OWN directory — so temporarily drop a copy of specfont.bin
    # next to the generated .asm and remove it again afterwards.
    specfont_src = ZXBASIC_ROOT / "src" / "lib" / "arch" / "zx81sd" / "runtime" / "specfont.bin"
    specfont_dst = workdir / "specfont.bin"
    specfont_copied = False
    if specfont_src.is_file() and not specfont_dst.exists():
        shutil.copy2(specfont_src, specfont_dst)
        specfont_copied = True

    print()
    print("== zxbasm.py (asm -> bin + map) ==")
    print(" ".join(zxbasm_cmd))
    try:
        subprocess.run(zxbasm_cmd, check=True)
    finally:
        if specfont_copied:
            specfont_dst.unlink(missing_ok=True)

    print()
    print(f"Generated: {asm_path}")
    print(f"Generated: {bin_path}")
    print(f"Generated: {map_path}")


if __name__ == "__main__":
    main()
