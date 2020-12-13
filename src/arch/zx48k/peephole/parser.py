#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re
from collections import defaultdict

from typing import Any
from typing import Dict
from typing import List
from typing import NamedTuple
from typing import Optional
from typing import Tuple
from typing import Union

import src.api.global_

from src.arch.zx48k.peephole import evaluator
from src.arch.zx48k.peephole import pattern

TreeType = List[Union[str, List[Any]]]

COMMENT = ';;'
RE_REGION = re.compile(r'([_a-zA-Z][a-zA-Z0-9]*)[ \t]*{{')
RE_DEF = re.compile(r'([_a-zA-Z][a-zA-Z0-9]*)[ \t]*:[ \t]*(.*)')
RE_IFPARSE = re.compile(r'"(""|[^"])*"|[(),]|\b[_a-zA-Z]+\b|[^," \t()]+')
RE_ID = re.compile(r'\b[_a-zA-Z]+\b')
RE_INT = re.compile(r'^\d+$')

# Names of the different params
REG_IF = 'IF'
REG_REPLACE = 'REPLACE'
REG_WITH = 'WITH'
REG_DEFINE = 'DEFINE'
O_LEVEL = 'OLEVEL'
O_FLAG = 'OFLAG'

# Operators : priority (lower number -> highest priority)
IF_OPERATORS = {
    evaluator.OP_NMUL: 3,
    evaluator.OP_NDIV: 3,
    evaluator.OP_PLUS: 5,
    evaluator.OP_NPLUS: 5,
    evaluator.OP_NSUB: 5,
    evaluator.OP_NE: 10,
    evaluator.OP_EQ: 10,
    evaluator.OP_AND: 15,
    evaluator.OP_OR: 20,
    evaluator.OP_IN: 25,
    evaluator.OP_COMMA: 30
}


# Which one of the above are REGIONS (that is, {{ ... }} blocks)
REGIONS = {REG_IF, REG_WITH, REG_REPLACE, REG_DEFINE}
# Which one of the above are scalars (NAME: VALUE definitions)
SCALARS = {O_FLAG, O_LEVEL}
# Which one of the above must be integers (0...N)
NUMERIC = {O_FLAG, O_LEVEL}

# Put here all of the above that are required
REQUIRED = (REG_REPLACE, REG_WITH, O_LEVEL, O_FLAG)


def simplify_expr(expr: List[Any]) -> List[Any]:
    """ Simplifies ("unnest") a list, removing redundant brackets.
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
    expr: evaluator.Evaluator


def parse_ifline(if_line: str, lineno: int) -> Optional[TreeType]:
    """ Given a line from within a IF region (i.e. $1 == "af'")
    returns it as a list of tokens ['$1', '==', "af'"]
    """
    stack: List[TreeType] = []
    expr: TreeType = []
    paren = 0
    error_ = False

    while not error_ and if_line:
        if_line = if_line.strip()
        if not if_line:
            break
        qq = RE_IFPARSE.match(if_line)
        if not qq:
            error_ = True
            break

        tok = qq.group()
        if not RE_ID.match(tok):
            for oper in evaluator.OPERS:
                if tok.startswith(oper):
                    tok = tok[:len(oper)]
                    break

        if_line = if_line[len(tok):]

        if tok == '(':
            paren += 1
            stack.append(expr)
            expr = []
            continue

        if tok in evaluator.UNARY:
            stack.append(expr)
            expr = [tok]
            continue

        if tok == ')':
            paren -= 1
            if paren < 0:
                src.api.errmsg.warning(lineno, "Too much closed parenthesis")
                return None

            if expr and expr[-1] == evaluator.OP_COMMA:
                src.api.errmsg.warning(lineno, "missing element in list")
                return None

            stack[-1].append(expr)
            expr = stack.pop()
        else:
            if len(tok) > 1 and tok[0] == tok[-1] == '"':
                tok = tok[1:-1]
            expr.append(tok)

        if tok == evaluator.OP_COMMA:
            if len(expr) < 2 or expr[-2] == tok:
                src.api.errmsg.warning(lineno, "Unexpected {} in list".format(tok))
                return None

        while len(expr) == 2 and isinstance(expr[-2], str):
            op: Union[str, TreeType] = expr[-2]
            if op in evaluator.UNARY:
                stack[-1].append(expr)
                expr = stack.pop()
            else:
                break

        if len(expr) == 3 and expr[1] != evaluator.OP_COMMA:
            left_, op, right_ = expr  # type: ignore
            if not isinstance(op, str) or op not in IF_OPERATORS:
                src.api.errmsg.warning(lineno, "Unexpected binary operator '{0}'".format(op))
                return None
            if isinstance(left_, list) and len(left_) == 3 and IF_OPERATORS[left_[-2]] > IF_OPERATORS[op]:
                expr = [[left_[:-2], left_[-2], [left_[-1], op, right_]]]  # Rebalance tree
            else:
                expr = [expr]

    if not error_ and paren:
        src.api.errmsg.warning(lineno, "unclosed parenthesis in IF section")
        return None

    while stack and not error_:
        stack[-1].append(expr)
        expr = stack.pop()

        if len(expr) == 2:
            op = expr[0]
            if not isinstance(op, str) or op not in evaluator.UNARY:
                src.api.errmsg.warning(lineno, "unexpected unary operator '{0}'".format(op))
                return None
        elif len(expr) == 3:
            op = expr[1]
            if not isinstance(op, str) or op not in evaluator.BINARY:
                src.api.errmsg.warning(lineno, "unexpected binary operator '{0}'".format(op))
                return None

    if error_:
        src.api.errmsg.warning(lineno, "syntax error in IF section")
        return None

    return simplify_expr(expr)


def parse_define_line(sourceline: SourceLine) -> Tuple[Optional[str], Optional[TreeType]]:
    """ Given a line $nnn = <expression>, returns a tuple the parsed
    ("$var", [expression]) or None, None if error. """
    if '=' not in sourceline.line:
        src.api.errmsg.warning(sourceline.lineno, "assignation '=' not found")
        return None, None

    result: List[str] = [x.strip() for x in sourceline.line.split('=', 1)]
    if not pattern.RE_SVAR.match(result[0]):  # Define vars
        src.api.errmsg.warning(sourceline.lineno, "'{0}' not a variable name".format(result[0]))
        return None, None

    right_part = parse_ifline(result[1], sourceline.lineno)
    if right_part is None:
        return None, None

    return result[0], right_part


def parse_str(spec: str) -> Optional[Dict[str, Union[str, int, TreeType]]]:
    """ Given a string with an optimizer template definition,
    parses it and return a python object as a result.
    If any error is detected, fname will be used as filename.
    """
    # States
    ST_INITIAL = 0
    ST_REGION = 1

    result: Dict[str, Any] = defaultdict(list)
    state = ST_INITIAL
    line_num = 0
    region_name = None
    is_ok = True

    def add_entry(key: str, val: Union[str, int, TreeType]) -> bool:
        key = key.upper()
        if key in result:
            src.api.errmsg.warning(line_num, "duplicated definition {0}".format(key))
            return False

        if key not in REGIONS and key not in SCALARS:
            src.api.errmsg.warning(line_num, "unknown definition parameter '{0}'".format(key))
            return False

        if key in NUMERIC:
            assert isinstance(val, str)
            if not RE_INT.match(val):
                src.api.errmsg.warning(line_num, "field '{0} must be integer".format(key))
                return False
            val = int(val)

        result[key] = val
        return True

    def check_entry(key: str) -> bool:
        if key not in result:
            src.api.errmsg.warning(line_num, "undefined section {0}".format(key))
            return False

        return True

    for line in spec.split('\n'):
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
            if line.endswith('}}'):
                line = line[:-2].strip()
                state = ST_INITIAL

            if line:
                result[region_name].append(SourceLine(line_num, line))  # type: ignore

            if state == ST_INITIAL:
                region_name = None
            continue

        src.api.errmsg.warning(line_num, "syntax error. Cannot parse file")
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
            src.api.errmsg.warning(source_line.lineno, "duplicated variable '{0}'".format(var_))
            is_ok = False
            break
        defines.append([var_, DefineLine(expr=evaluator.Evaluator(expr), lineno=source_line.lineno)])
        defined_vars.add(var_)
    result[REG_DEFINE] = defines

    if is_ok:
        for reg in [x for x in REGIONS if x != REG_DEFINE]:
            result[reg] = [x.line for x in result[reg]]

    if is_ok:
        reg_if = parse_ifline(' '.join(x for x in result[REG_IF]), line_num)
        if reg_if is None:
            is_ok = False
        else:
            result[REG_IF] = reg_if

    is_ok = is_ok and all(check_entry(x) for x in REQUIRED)

    if is_ok:
        if not result[REG_REPLACE]:  # Empty REPLACE region??
            src.api.errmsg.warning(line_num, "empty region {0}".format(REG_REPLACE))
            is_ok = False

    if not is_ok:
        src.api.errmsg.warning(line_num, "this optimizer template will be ignored due to errors")
        return None

    return result


def parse_file(fname: str):
    """ Opens and parse a file given by filename
    """
    tmp = src.api.global_.FILENAME
    src.api.global_.FILENAME = fname  # set filename so it shows up in error/warning msgs

    with open(fname, 'rt') as f:
        result = parse_str(f.read())

    src.api.global_.FILENAME = tmp  # restores original filename
    return result


if __name__ == '__main__':
    print(parse_file(sys.argv[1]))
