# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import itertools
import re

RE_SVAR = re.compile(r"(\$(?:\$|[0-9]+))")
RE_PARSE = re.compile(r'(\s+|"(?:[^"]|"")*")')


class BasicLinePattern:
    """Defines a pattern for a line, like 'push $1' being
    $1 a pattern variable
    """

    __slots__ = "line", "output", "re", "re_pattern", "vars"

    @staticmethod
    def sanitize(pattern):
        """Returns a sanitized pattern version of a string to be later
        compiled into a reg exp
        """
        meta = r".^$*+?{}[]\|()"
        return "".join(r"\%s" % x if x in meta else x for x in pattern)

    def __init__(self, line):
        self.line = "".join(x.strip() or " " for x in RE_PARSE.split(line) if x).strip()
        self.vars = []
        self.re_pattern = ""
        self.output = []

        for token in RE_PARSE.split(self.line):
            if token == " ":
                self.re_pattern += r"\s+"
                self.output.append(" ")
                continue
            subtokens = [x for x in RE_SVAR.split(token) if x]

            for tok in subtokens:
                if tok == "$$":
                    self.re_pattern += r"\$"
                    self.output.append("$")
                elif RE_SVAR.match(tok):
                    self.output.append(tok)
                    mvar = "_%s" % tok[1:]
                    if mvar not in self.vars:
                        self.vars.append(mvar)
                        self.re_pattern += "(?P<%s>.*)" % mvar
                    else:
                        self.re_pattern += r"\%i" % (self.vars.index(mvar) + 1)
                else:
                    self.output.append(tok)
                    self.re_pattern += BasicLinePattern.sanitize(tok)

        self.re = re.compile(self.re_pattern)
        self.vars = {x.replace("_", "$") for x in self.vars}


class LinePattern(BasicLinePattern):
    """Defines a pattern to match against a source assembler.
    Given an assembler instruction with substitution variables
    ($1, $2, ...) creates an instance that matches against a list
    of real assembler instructions. e.g.
      push $1
    matches against
      push af
    and bounds $1 to 'af'
    Note that $$ matches against the $ sign

    Returns whether the pattern matched (True) or not.
    If it matched, the vars_ dictionary will be updated with unified vars.
    """

    __slots__ = "line", "output", "re", "re_pattern", "vars"

    def match(self, line: str, vars_: dict[str, str]) -> bool:
        match = self.re.match(line)
        if match is None:
            return False

        mdict = match.groupdict()
        if any(mdict.get(k, v) != v for k, v in vars_.items()):
            return False

        vars_.update(mdict)
        return True

    def __repr__(self):
        return repr(self.re)


class BlockPattern:
    """Given a list asm instructions, tries to match them"""

    __slots__ = "lines", "patterns", "vars"

    def __init__(self, lines: list[str]):
        lines = [x.strip() for x in lines]
        self.patterns = [LinePattern(x) for x in lines if x]
        self.lines = [pattern.line for pattern in self.patterns]
        self.vars = set(itertools.chain(*[p.vars for p in self.patterns]))

    def __len__(self):
        return len(self.lines)

    def match(self, instructions: list[str], start: int = 0) -> dict[str, str] | None:
        """Given a list of instructions and a starting point,
        returns whether this pattern matches or not from such point
        onwards.
        E.g. given the pattern:
          push $1
          pop $1
        and the list
          ld a, 5
          push af
          pop af
        this pattern will match at position 1
        """
        lines = instructions[start:]
        if len(self) > len(lines):
            return None

        univars: dict[str, str] = {}
        if not all(patt.match(line, vars_=univars) for patt, line in zip(self.patterns, lines)):
            return None

        return {"$" + k[1:]: v for k, v in univars.items()}

    def __repr__(self):
        return str([repr(x) for x in self.patterns])
