#!/usr/bin/env python3

import re
import sys

INDENT = 4 * " "
RE_END_ASM = re.compile("^END[ \t]+ASM$")


def process_file(fname: str):
    IN_ASM = False

    with open(fname, "rt", encoding="utf-8") as f:
        lines = f.readlines()

    i = -1
    while i < len(lines) - 1:
        i += 1
        lines[i] = lines[i].rstrip(" \n\r\t")
        line = lines[i].strip(" \n\r\t")
        print(line)

        if not line:
            lines[i] = ""
            continue

        if not IN_ASM and line.upper() == "ASM":
            if lines[i + 1].lower().strip().startswith("push namespace"):
                continue

            lines.insert(i + 1, f"{INDENT}push namespace core")
            IN_ASM = True
            continue

        if not IN_ASM:
            continue

        if RE_END_ASM.match(line.upper()):
            lines.insert(i, f"{INDENT}pop namespace")
            IN_ASM = False
            continue

        if line != lines[i]:
            if lines[i].startswith(" ") or lines[i].startswith("\t"):
                lines[i] = f"{INDENT}{line}"
            else:
                lines[i] = line

    with open(fname, "wt", encoding="utf-8") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    process_file(sys.argv[1])
