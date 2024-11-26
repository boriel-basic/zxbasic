import re
from collections import defaultdict
from types import MappingProxyType
from typing import Any, Final, NamedTuple

from src.api import errmsg, global_

from . import pattern
from .evaluator import BINARY, FN, OPERS, UNARY, Evaluator

TreeType = list[str | list["TreeType"]]

COMMENT: Final[str] = ";;"
RE_REGION = re.compile(r"([_a-zA-Z][a-zA-Z0-9]*)[ \t]*\{\{$")
RE_DEF = re.compile(r"([_a-zA-Z][a-zA-Z0-9]*)[ \t]*:[ \t]*(.*)")
RE_IFPARSE = re.compile(r'"(""|[^"])*"|[(),]|\b[_a-zA-Z]+\b|[^," \t()]+')
RE_ID = re.compile(r"\b[_a-zA-Z]+\b")
RE_INT = re.compile(r"^\d+$")

# Names of the different params
REG_IF = "IF"
REG_REPLACE = "REPLACE"
REG_WITH = "WITH"
REG_DEFINE = "DEFINE"
O_LEVEL = "OLEVEL"
O_FLAG = "OFLAG"

# Operators : precedence (lower number -> highest priority)
IF_OPERATORS: Final[MappingProxyType[FN, int]] = MappingProxyType(
    {
        FN.OP_NMUL: 3,
        FN.OP_NDIV: 3,
        FN.OP_PLUS: 5,
        FN.OP_NPLUS: 5,
        FN.OP_NSUB: 5,
        FN.OP_NE: 10,
        FN.OP_EQ: 10,
        FN.OP_AND: 15,
        FN.OP_OR: 20,
        FN.OP_IN: 25,
        FN.OP_COMMA: 30,
    }
)


# Which one of the above are REGIONS (that is, {{ ... }} blocks)
REGIONS = {REG_IF, REG_WITH, REG_REPLACE, REG_DEFINE}
# Which one of the above are scalars (NAME: VALUE definitions)
SCALARS = {O_FLAG, O_LEVEL}
# Which one of the above must be integers (0...N)
NUMERIC = {O_FLAG, O_LEVEL}

# Put here all of the above that are required
REQUIRED = (REG_REPLACE, REG_WITH, O_LEVEL, O_FLAG)


class PeepholeParserSyntaxError(SyntaxError):
    pass


def simplify_expr(expr: list[Any]) -> list[Any]:
    """Simplifies ("unnest") a list, removing redundant brackets.
    i.e. [[x, [[y]]] becomes [x, [y]]
    """
    if not isinstance(expr, list):
        return expr

    if len(expr) == 1 and isinstance(expr[0], list):
        return simplify_expr(expr[0])

    return [simplify_expr(x) for x in expr]


# Stores a source opt line
class SourceLine(NamedTuple):
    lineno: int
    line: str


# Defines a define expr with its linenum
class DefineLine(NamedTuple):
    lineno: int
    expr: Evaluator


class Tokenizer:
    def __init__(self, source: str, lineno: int) -> None:
        self.source = source
        self.lineno = lineno

    def get_token(self) -> str:
        """Returns next token, or "" as EOL"""
        tok = self.lookahead()
        self.source = self.source[len(tok) :]
        return tok

    def get_next_token(self) -> str:
        if self.has_finished():
            raise PeepholeParserSyntaxError("Unexpected EOL")

        return self.get_token()

    def has_finished(self) -> bool:
        return self.source == ""

    def lookahead(self) -> str:
        """Returns next token, or "" as EOL"""
        self.source = self.source.strip()
        if self.has_finished():
            return ""

        qq = RE_IFPARSE.match(self.source)
        if not qq:
            raise PeepholeParserSyntaxError(f"Syntax error in line {self.lineno}: {self.source}")

        tok = qq.group()
        if not RE_ID.match(tok):
            for oper in OPERS:
                if tok.startswith(oper):
                    tok = tok[: len(oper)]
                    break

        return tok


def parse_ifline(if_line: str, lineno: int) -> TreeType | None:
    """Given a line from within a IF region (i.e. $1 == "af'")
    returns it as a list of tokens ['$1', '==', "af'"]
    """
    stack: list[TreeType] = []
    expr: TreeType = []
    paren = 0
    error_ = False
    tokenizer = Tokenizer(if_line, lineno)

    while not tokenizer.has_finished():
        try:
            tok = tokenizer.get_token()
        except PeepholeParserSyntaxError as e:
            errmsg.warning(lineno, str(e))
            return None

        if tok == "(":
            paren += 1
            stack.append(expr)
            expr = []
            continue

        if tok in UNARY:
            stack.append(expr)
            expr = [tok]
            continue

        if tok == ")":
            paren -= 1
            if paren < 0:
                errmsg.warning(lineno, "Too much closed parenthesis")
                return None

            if expr and expr[-1] == FN.OP_COMMA:
                errmsg.warning(lineno, "missing element in list")
                return None

            if any(x != FN.OP_COMMA for i, x in enumerate(expr) if i % 2):
                errmsg.warning(lineno, f"Invalid list {expr}")
                return None

            stack[-1].append(expr)
            expr = stack.pop()
        else:
            if len(tok) > 1 and tok[0] == tok[-1] == '"':
                tok = tok[1:-1]
            expr.append(tok)

        if tok == FN.OP_COMMA:
            if len(expr) < 2 or expr[-2] == tok:
                errmsg.warning(lineno, f"Unexpected {tok} in list")
                return None

        while len(expr) == 2 and isinstance(expr[0], str):
            op: str = expr[0]
            if op in UNARY:
                stack[-1].append(expr)
                expr = stack.pop()
            else:
                break

        if len(expr) == 3 and expr[1] != FN.OP_COMMA:
            left_, op, right_ = expr
            if not isinstance(op, str) or op not in IF_OPERATORS:
                errmsg.warning(lineno, f"Unexpected binary operator '{op}'")
                return None

            oper = FN(op)
            if isinstance(left_, list) and len(left_) == 3:
                oper2 = FN(left_[-2])
                if IF_OPERATORS[oper2] > IF_OPERATORS[oper]:
                    expr = [[left_[:-2], left_[-2], [left_[-1], op, right_]]]  # Rebalance tree
                    continue

            expr = [expr]

    if error_:
        errmsg.warning(lineno, "syntax error in IF section")
        return None

    if paren:
        errmsg.warning(lineno, "unclosed parenthesis in IF section")
        return None

    while stack and not error_:
        stack[-1].append(expr)
        expr = stack.pop()

        if len(expr) == 2:
            op = expr[0]
            if not isinstance(op, str) or op not in UNARY:
                errmsg.warning(lineno, f"unexpected unary operator '{op}'")
                return None
        elif len(expr) == 3:
            op = expr[1]
            if not isinstance(op, str) or op not in BINARY:
                errmsg.warning(lineno, f"unexpected binary operator '{op}'")
                return None

    expr = simplify_expr(expr)
    if len(expr) == 2 and isinstance(expr[-1], str) and expr[-1] in BINARY:
        errmsg.warning(lineno, f"Unexpected binary operator '{expr[-1]}'")
        return None

    if len(expr) == 3 and (expr[1] not in BINARY or expr[1] == FN.OP_COMMA):
        errmsg.warning(lineno, f"Unexpected binary operator '{expr[1]}'")
        return None

    if len(expr) > 3:
        errmsg.warning(lineno, "Lists not allowed in IF section condition. Missing operator")
        return None

    return expr


def parse_define_line(sourceline: SourceLine) -> tuple[str | None, TreeType | None]:
    """Given a line $nnn = <expression>, returns a tuple the parsed
    ("$var", [expression]) or None, None if error."""
    if "=" not in sourceline.line:
        errmsg.warning(sourceline.lineno, "assignation '=' not found")
        return None, None

    result: list[str] = [x.strip() for x in sourceline.line.split("=", 1)]
    if not pattern.RE_SVAR.match(result[0]):  # Define vars
        errmsg.warning(sourceline.lineno, f"'{result[0]}' not a variable name")
        return None, None

    right_part = parse_ifline(result[1], sourceline.lineno)
    if right_part is None:
        return None, None

    return result[0], right_part


def parse_str(spec: str) -> dict[str, str | int | TreeType] | None:
    """Given a string with an optimizer template definition,
    parses it and return a python object as a result.
    If any error is detected, fname will be used as filename.
    """
    # States
    ST_INITIAL = 0
    ST_REGION = 1

    result: dict[str, Any] = defaultdict(list)
    state = ST_INITIAL
    line_num = 0
    region_name = None
    is_ok = True

    def add_entry(key: str, val: str | int | TreeType) -> bool:
        key = key.upper()
        if key in result:
            errmsg.warning(line_num, f"duplicated definition {key}")
            return False

        if key not in REGIONS and key not in SCALARS:
            errmsg.warning(line_num, f"unknown definition parameter '{key}'")
            return False

        if key in NUMERIC:
            assert isinstance(val, str)
            if not RE_INT.match(val):
                errmsg.warning(line_num, f"field '{key} must be integer")
                return False
            val = int(val)

        result[key] = val
        return True

    def check_entry(key: str) -> bool:
        if key not in result:
            errmsg.warning(line_num, f"undefined section {key}")
            return False

        return True

    for line in spec.split("\n"):
        line = line.strip()
        line_num += 1

        if not line:
            continue  # Ignore blank lines

        if state == ST_INITIAL:
            if line.startswith(COMMENT):
                continue

            x = RE_REGION.match(line)
            if x:
                region_name = x.groups()[0]
                state = ST_REGION
                add_entry(region_name, [])
                continue

            x = RE_DEF.match(line)
            if x:
                if not add_entry(*x.groups()):
                    is_ok = False
                    break
                continue
        elif state == ST_REGION:
            if line.endswith("}}"):
                line = line[:-2].strip()
                state = ST_INITIAL

            if line:
                result[region_name].append(SourceLine(line_num, line))  # type: ignore

            if state == ST_INITIAL:
                region_name = None
            continue

        errmsg.warning(line_num, "syntax error. Cannot parse file")
        is_ok = False
        break

    defines = []
    defined_vars = set()
    for source_line in result[REG_DEFINE]:
        var_, expr = parse_define_line(source_line)
        if var_ is None or expr is None:
            is_ok = False
            break
        if var_ in defined_vars:
            errmsg.warning(source_line.lineno, f"duplicated variable '{var_}'")
            is_ok = False
            break
        defines.append([var_, DefineLine(expr=Evaluator(expr), lineno=source_line.lineno)])
        defined_vars.add(var_)
    result[REG_DEFINE] = defines

    if is_ok:
        for reg in [x for x in REGIONS if x != REG_DEFINE]:
            result[reg] = [x.line for x in result[reg]]

    if is_ok:
        reg_if = parse_ifline(" ".join(x for x in result[REG_IF]), line_num)
        if reg_if is None:
            is_ok = False
        else:
            result[REG_IF] = reg_if

    is_ok = is_ok and all(check_entry(x) for x in REQUIRED)

    if is_ok:
        if not result[REG_REPLACE]:  # Empty REPLACE region??
            errmsg.warning(line_num, f"empty region {REG_REPLACE}")
            is_ok = False

    if not is_ok:
        errmsg.warning(line_num, "this optimizer template will be ignored due to errors")
        return None

    return result


def parse_file(fname: str) -> dict[str, str | int | list[str | list]] | None:
    """Opens and parse a file given by filename"""
    tmp = global_.FILENAME
    global_.FILENAME = fname  # set filename so it shows up in error/warning msgs

    with open(fname, "rt", encoding="utf-8") as f:
        result = parse_str(f.read())

    global_.FILENAME = tmp  # restores original filename
    return result
