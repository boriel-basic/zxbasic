# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import os
from collections.abc import Iterable
from typing import NamedTuple

from src.api import debug, errmsg
from src.arch.z80.peephole import parser
from src.arch.z80.peephole.evaluator import Evaluator
from src.arch.z80.peephole.parser import (
    O_FLAG,
    O_LEVEL,
    REG_DEFINE,
    REG_IF,
    REG_REPLACE,
    REG_WITH,
    DefineLine,
)
from src.arch.z80.peephole.pattern import BlockPattern
from src.arch.z80.peephole.template import BlockTemplate


class OptPattern(NamedTuple):
    level: int
    flag: int
    patt: BlockPattern
    cond: Evaluator
    template: BlockTemplate
    parsed: dict[str, list[str] | int]
    defines: list[tuple[str, DefineLine]]
    fname: str


OPTS_PATH = os.path.join(os.path.dirname(__file__), "opts")

# Global list of optimization patterns
PATTERNS: list[OptPattern] = []

# Max len of any pattern read
MAXLEN: int = 0


def read_opt(opt_path: str) -> OptPattern | None:
    """Given a path to an opt file, parses it and returns an OptPattern
    object, or None if there were errors
    """
    global MAXLEN

    fpath = os.path.abspath(opt_path)
    if not os.path.isfile(fpath):
        return None

    parsed_result = parser.parse_file(fpath)
    if parsed_result is None:
        return None

    try:
        pattern_ = OptPattern(
            level=parsed_result[O_LEVEL],
            flag=parsed_result[O_FLAG],
            patt=BlockPattern(parsed_result[REG_REPLACE]),
            template=BlockTemplate(parsed_result[REG_WITH]),
            cond=Evaluator(parsed_result[REG_IF]),
            parsed=parsed_result,
            defines=parsed_result[REG_DEFINE],
            fname=os.path.basename(fpath),
        )

        for var_, define_ in pattern_.defines:
            if var_ in pattern_.patt.vars:
                errmsg.warning(define_.lineno, f"variable '{var_}' already defined in pattern", fpath)
                errmsg.warning(define_.lineno, "this template will be ignored", fpath)
                return None

    except (ValueError, KeyError, TypeError):
        errmsg.warning(1, "There is an error in this template and it will be ignored", fpath)
    else:
        MAXLEN = max(len(pattern_.patt), MAXLEN or 0)
        return pattern_

    return None


def read_opts(folder_path: str, result: list[OptPattern] | None = None) -> list[OptPattern]:
    """Reads (and parses) all *.opt files from the given directory
    retaining only those with no errors.
    """
    if result is None:
        result = []

    try:
        files_to_read = [f for f in os.listdir(folder_path) if f.endswith(".opt")]
    except (FileNotFoundError, NotADirectoryError, PermissionError):
        return result

    for fname in files_to_read:
        pattern_ = read_opt(os.path.join(folder_path, fname))
        if pattern_ is None:
            continue

        result.append(pattern_)

    result[:] = sorted(result, key=lambda x: x.flag)
    return result


def apply_match(asm_list: list[str], patterns_list: Iterable[OptPattern], index: int = 0) -> bool:
    """Tries to match optimization patterns against the given ASM list block, starting
    at offset `index` within that block.

    Only patterns having an O_LEVEL between o_min and o_max (both included) will be taken
    into account.

    :param asm_list: A list of asm instructions (will be changed)
    :param patterns_list: A list of OptPatterns to try against
    :param index: Index to start matching from (defaults to 0)
    :return: True if there was a match and asm_list code was changed
    """
    for p in patterns_list:
        match = p.patt.match(asm_list, start=index)
        if match is None:  # HINT: {} is also a valid match
            continue

        for var, defline in p.defines:
            match[var] = defline.expr.eval(match)

        if not p.cond.eval(match):
            continue

        # All patterns have matched successfully. Apply this pattern
        matched = asm_list[index : index + len(p.patt)]
        applied = p.template.filter(match)
        asm_list[index : index + len(p.patt)] = applied
        errmsg.info("pattern applied [{}:{}]".format("%03i" % p.flag, p.fname))
        debug.__DEBUG__("matched: \n    {}".format("\n    ".join(matched)), level=1)
        return True

    return False


def init():
    global MAXLEN

    MAXLEN = 0
    PATTERNS.clear()


def main(list_of_directories: list[str] | None = None, force: bool = False):
    """Initializes the module and load all the *.opt files
    containing patterns and parses them. Valid .opt files will be stored in
    PATTERNS
    """
    global PATTERNS
    global MAXLEN

    if not force and MAXLEN:  # If already loaded, don't reload (cache)
        return

    init()

    for directory in list_of_directories or [OPTS_PATH]:
        read_opts(directory, PATTERNS)
