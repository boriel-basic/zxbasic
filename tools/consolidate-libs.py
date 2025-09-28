#!/usr/bin/env python

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
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


def fold_files(scan: dict[FileInfo, list[str]]) -> None:
    for path, files in scan.items():
        if len(files) == 1:
            continue

        main_file = files[0]
        for file in files[1:]:
            print(f"Linking {main_file} to {file}")
            os.unlink(file)
            os.link(main_file, file)


def main():
    scan = scan_arch(ROOT_DIR)
    fold_files(scan)


if __name__ == "__main__":
    main()
