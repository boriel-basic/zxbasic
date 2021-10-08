#!/usr/bin/env python3
import sys

INDENT = 4 * " "


def process_file(fname: str):
    with open(fname, "rt", encoding="utf-8") as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        line = line.strip(" \n\r\t")
        if not line:
            lines[i] = ""
            continue

        if line.lower().startswith("push namespace"):
            return

        if line != lines[i]:
            if lines[i].startswith(" ") or lines[i].startswith("\t"):
                lines[i] = f"{INDENT}{line}"
            else:
                lines[i] = line

    for i, line in enumerate(lines):
        if line.strip() and not line.strip().startswith(";") and not line.strip().startswith("#"):
            break
    else:
        return

    lines.insert(i, f"{INDENT}push namespace core\n")

    for j, line in enumerate(lines[::-1]):
        if line.strip() and not line.strip().startswith(";"):
            break

    lines.insert(len(lines) - j, f"\n{INDENT}pop namespace\n")

    with open(fname, "wt", encoding="utf-8") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    process_file(sys.argv[1])
