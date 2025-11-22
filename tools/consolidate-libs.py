#!/usr/bin/env python

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

__doc__ = """Scans src/lib/<arch>/** and does hardlinks to files
with the same name and content"""

import glob
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import NamedTuple

ROOT_DIR = Path(__file__).parent.parent.absolute() / "src" / "lib" / "arch"
ARCHS = "zx48k", "zxnext"
COPYRIGHT_HEADER = """' ----------------------------------------------------------------
' This file is released under the MIT License
'
' Copyleft (k) 2008
' by Jose Rodriguez-Rosa (a.k.a. Boriel) <https://www.boriel.com>
' ----------------------------------------------------------------
"""
ARCH_PRIO = {
    "zx48k": 0,
    "zxnext": 1,
}


class FileInfo(NamedTuple):
    path: str
    hash: int


def get_file_list(root: Path) -> list[str]:
    filelist = glob.glob(str(root / "**" / "*"), recursive=True)
    return [f for f in filelist if os.path.isfile(f)]


def scan_arch(root: Path) -> dict[FileInfo, list[str]]:
    result = defaultdict(list)
    re_arch = re.compile(r"^.*?/src/lib/arch/[^/]+/(.*)$")

    files = get_file_list(root)
    for file in files:
        match = re_arch.match(file)
        if not match:
            continue

        path = match.group(1)
        result[FileInfo(path=path, hash=hash(open(file, "rb").read()))].append(file)

    return result


def file_arch(fname: str) -> str:
    """Returns the arch the file belongs to.
    The arch is extracted from the filename path.
    """
    return re.match(r"^.*?/src/lib/arch/([^/]+)/.*$", fname).group(1)


def relative_filename(fname: str) -> str:
    return re.sub(r"^.*?/src/lib/arch/[^/]+/[^/]+/", "", fname)


def fold_files(scan: dict[FileInfo, list[str]]) -> None:
    for path, files in scan.items():
        if len(files) == 1:
            continue

        # Get the file with the arch with the highest priority (which is the lowest number)
        main_file = min(files, key=lambda f: ARCH_PRIO[file_arch(f)])
        print(main_file)
        main_file_basename = relative_filename(main_file)
        main_file_ext = os.path.splitext(main_file_basename)[1]
        if main_file_ext not in (".asm", ".bas"):
            continue

        arch = file_arch(main_file)
        for file in files:
            if file == main_file:
                continue

            print(f"Linking {file} to {main_file} with an include")
            with open(file, "wt", encoding="utf-8") as f:
                f.write(COPYRIGHT_HEADER)
                f.write(f"\n#include once [arch:{arch}] <{main_file_basename}>\n")


def main():
    scan = scan_arch(ROOT_DIR)
    fold_files(scan)


if __name__ == "__main__":
    main()
