#!/usr/bin/env python3
"""
build_sd81.py — one-shot build: BASIC source -> zx81sd binary -> SD81
Booster package (page files + tokenized .P loader), in a single command.

Chains the two steps that had to be run by hand throughout zx81sd
development:
  1. zxbc.py --arch=zx81sd -D __ZX81SD__ -o <base>.bin -M <base>.map
     (compiles the BASIC source; -M keeps the symbol map in sync with
     the binary — a stale/missing .map was a repeated source of
     confusion when live-debugging on real hardware/emulator)
  2. split_sd81.py <base>.bin <BASE>   (splits into 8KB SD81 pages and
     generates <BASE>.P, the tokenized BASIC loader)

Usage:
  python build_sd81.py <source.bas> [output_base] [--copy-to DIR] [--asm]
                        [-O LEVEL] [-D MACRO ...] [zxbc.py extra args...]

  output_base defaults to the source file's name (without extension),
  uppercased — same convention split_sd81.py already enforces (must be
  representable in the ZX81 charset: letters/digits, no underscore).

  --copy-to DIR: after building, also copy the page files, the .P
  loader, and boot1.bin (from this tools/ folder) to DIR (e.g. an
  emulator's virtual-SD test folder).

  --asm: also emit <base>.asm, the generated assembly listing (a second
  zxbc.py pass with -f asm, same source/optimize/defines). Off by
  default (it's a much bigger file than the .map and rarely needed) —
  turn it on when tracing a bug live against the .map/disassembly, to
  see the actual instructions around a given address instead of just
  its label. The .map (symbol addresses) is still always generated,
  unconditionally, as before.

  __ZX81SD__ is always defined; pass more -D flags to add extras.
  Any unrecognized argument is forwarded to zxbc.py as-is (e.g. to
  tweak heap size, warnings, etc.).

Example:
  python build_sd81.py C:/ClaudeCode/ZXOilPanic/oilpanic.bas OILPANIC ^
      --copy-to C:/ClaudeCode/Eightyone2/EightyOne/SD81/test
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
ZXBASIC_ROOT = TOOLS_DIR.parents[3]  # tools -> zx81sd -> arch -> src -> <zxbasic root>
ZXBC = ZXBASIC_ROOT / "zxbc.py"
SPLIT_SCRIPT = TOOLS_DIR / "split_sd81.py"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("source", help="BASIC source file (.bas)")
    ap.add_argument(
        "output_base", nargs="?", help="Output base name (default: source file name)"
    )
    ap.add_argument(
        "--copy-to", metavar="DIR", help="Also copy the page files + .P loader here"
    )
    ap.add_argument(
        "--asm", action="store_true", help="Also emit <base>.asm (the generated assembly listing)"
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
    args, extra = ap.parse_known_args()

    if not ZXBC.is_file():
        sys.exit(f"Error: zxbc.py not found at {ZXBC} (unexpected repo layout)")
    if not SPLIT_SCRIPT.is_file():
        sys.exit(f"Error: split_sd81.py not found at {SPLIT_SCRIPT}")

    source = Path(args.source).resolve()
    if not source.is_file():
        sys.exit(f"Error: source file not found: {source}")

    base = args.output_base or source.stem
    workdir = source.parent
    bin_path = workdir / f"{base}.bin"
    map_path = workdir / f"{base}.map"

    zxbc_cmd = [
        sys.executable,
        str(ZXBC),
        str(source),
        "--arch=zx81sd",
        "-O",
        args.optimize,
        "-o",
        str(bin_path),
        "-M",
        str(map_path),
    ]
    for d in ["__ZX81SD__"] + args.define:
        zxbc_cmd += ["-D", d]
    zxbc_cmd += extra

    print("== zxbc.py ==")
    print(" ".join(zxbc_cmd))
    subprocess.run(zxbc_cmd, check=True)

    if args.asm:
        asm_path = workdir / f"{base}.asm"
        asm_cmd = [
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
            asm_cmd += ["-D", d]
        asm_cmd += extra

        print()
        print("== zxbc.py (asm) ==")
        print(" ".join(asm_cmd))
        subprocess.run(asm_cmd, check=True)

    print()
    print("== split_sd81.py ==")
    split_cmd = [sys.executable, str(SPLIT_SCRIPT), str(bin_path), base]
    print(" ".join(split_cmd))
    subprocess.run(split_cmd, check=True, cwd=workdir)

    if args.copy_to:
        dest = Path(args.copy_to)
        dest.mkdir(parents=True, exist_ok=True)
        base_upper = base.upper()
        copied = []
        for pattern in (f"{base_upper}P*.BIN", f"{base_upper}.P"):
            for f in workdir.glob(pattern):
                shutil.copy2(f, dest / f.name)
                copied.append(f.name)

        boot1 = TOOLS_DIR / "boot1.bin"
        if boot1.is_file():
            shutil.copy2(boot1, dest / boot1.name)
            copied.append(boot1.name)
        else:
            print(f"  Warning: boot1.bin not found at {boot1}")

        print()
        print(f"== copied to {dest} ==")
        if copied:
            for name in sorted(copied):
                print(f"  {name}")
        else:
            print(f"  Warning: nothing matched {base_upper}P*.BIN / {base_upper}.P in {workdir}")


if __name__ == "__main__":
    main()
