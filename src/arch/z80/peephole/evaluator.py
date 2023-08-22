# -*- coding: utf-8 -*-
from __future__ import annotations

import re
from enum import Enum, unique
from typing import Any, Callable, Dict, List, Optional, Union

from src.api import utils
from src.arch.z80.optimizer import helpers, memcell

from .pattern import RE_SVAR
from .template import UnboundVarError


@unique
class FN(str, Enum):
    OP_NOT = "!"
    OP_PLUS = "+"
    OP_EQ = "=="
    OP_NE = "<>"
    OP_AND = "&&"
    OP_OR = "||"
    OP_IN = "IN"
    OP_COMMA = ","
    OP_NPLUS = ".+"
    OP_NSUB = ".-"
    OP_NMUL = ".*"
    OP_NDIV = "./"
    IS_ASM = "IS_ASM"
    IS_INDIR = "IS_INDIR"
    IS_REG16 = "IS_REG16"
    IS_REG8 = "IS_REG8"
    IS_LABEL = "IS_LABEL"
    IS_IMMED = "IS_IMMED"
    LEN = "LEN"
    INSTR = "INSTR"
    HIREG = "HIREG"
    LOREG = "LOREG"
    HIVAL = "HIVAL"
    LOVAL = "LOVAL"
    GVAL = "GVAL"
    IS_REQUIRED = "IS_REQUIRED"
    CTEST = "CTEST"
    NEEDS = "NEEDS"
    FLAGVAL = "FLAGVAL"


# Reg expr patterns
RE_IXIY_IDX = re.compile(r"^\([ \t]*i[xy][ \t]*[-+][ \t]*.+\)$")


# Unary functions and operators
UNARY: Dict[FN, Callable[[str], Union[Optional[str], bool]]] = {
    FN.OP_NOT: lambda x: not x,
    FN.IS_ASM: lambda x: x.startswith("##ASM"),
    FN.IS_INDIR: lambda x: bool(RE_IXIY_IDX.match(x)),
    FN.IS_REG16: lambda x: x.strip().lower() in ("af", "bc", "de", "hl", "ix", "iy"),
    FN.IS_REG8: lambda x: x.strip().lower() in ("a", "b", "c", "d", "e", "h", "l", "ixh", "ixl", "iyh", "iyl"),
    FN.IS_LABEL: lambda x: x.strip()[-1:] == ":",
    FN.IS_IMMED: lambda x: not x.strip().startswith("("),
    FN.LEN: lambda x: str(len(x.split())),
    FN.INSTR: lambda x: x.strip().split()[0],
    FN.HIREG: lambda x: {"af": "a", "bc": "b", "de": "d", "hl": "h", "ix": "ixh", "iy": "iyh"}.get(
        x.strip().lower(), ""
    ),
    FN.LOREG: lambda x: {"af": "f", "bc": "c", "de": "e", "hl": "l", "ix": "ixl", "iy": "iyl"}.get(
        x.strip().lower(), ""
    ),
    FN.HIVAL: helpers.HI16_val,
    FN.LOVAL: helpers.LO16_val,
    FN.GVAL: lambda x: helpers.new_tmp_val(),  # To be updated in the O3 optimizer
    FN.IS_REQUIRED: lambda x: True,  # by default always required
    FN.CTEST: lambda x: memcell.MemCell(x, 1).condition_flag,  # condition test, if any. E.g. retz returns 'z'
    FN.NEEDS: lambda x: memcell.MemCell(x[0], 1).needs(x[1]),
    FN.FLAGVAL: lambda x: helpers.new_tmp_val(),
}

# Binary operators
LambdaType = Callable[[], Any]

BINARY: Dict[FN, Callable[[LambdaType, LambdaType], Union[str, bool, List[LambdaType]]]] = {
    FN.OP_EQ: lambda x, y: x() == y(),
    FN.OP_PLUS: lambda x, y: x() + y(),
    FN.OP_NE: lambda x, y: x() != y(),
    FN.OP_AND: lambda x, y: x() and y(),
    FN.OP_OR: lambda x, y: x() or y(),
    FN.OP_IN: lambda x, y: x() in y(),
    FN.OP_COMMA: lambda x, y: [x(), y()],
    FN.OP_NPLUS: lambda x, y: str(Number(x()) + Number(y())),
    FN.OP_NSUB: lambda x, y: str(Number(x()) - Number(y())),
    FN.OP_NMUL: lambda x, y: str(Number(x()) * Number(y())),
    FN.OP_NDIV: lambda x, y: str(Number(x()) / Number(y())),
}

OPERS = set(BINARY.keys()).union(UNARY.keys())


class Number:
    """Emulates a number that can be also None"""

    __slots__ = ("value",)

    def __init__(self, value):
        if isinstance(value, Number):
            self.value = value.value
            return
        self.value = utils.parse_int(str(value))

    def __repr__(self):
        return str(self.value) if self.value is not None else ""

    def __str__(self):
        return repr(self)

    def __add__(self, other: Number):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number("")
        return Number(self.value + other.value)

    def __sub__(self, other: Number):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number("")
        return Number(self.value - other.value)

    def __mul__(self, other: Number):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number("")
        return Number(self.value * other.value)

    def __floordiv__(self, other: Number):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number("")
        if not other.value:
            return None  # Div by Zero
        return Number(self.value / other.value)

    def __truediv__(self, other: Number):
        return self.__floordiv__(other)


class Evaluator:
    """Evaluates a given expression, which comes as an AST in nested lists. For example:
    ["ab" == ['a' + 'b']] will be evaluated as true.
    [5] will return 5
    [!0] will return True

    Operators:
        Unary:
            ! (not)

        Binary:
            == (equality)
            != (non equality)
            && (and)
            || (or)
            +  (addition or concatenation for strings)
    """

    __slots__ = "str_", "expression"

    def __init__(self, expression):
        """Initializes the object parsing the expression and preparing it for its (later)
        execution.
        :param expression: An expression (an AST in nested list parsed from the parser module
        :param unary: optional dict of unary functions (defaults to UNARY)
        :param binary: optional dict of binary operators (defaults to BINARY)
        """
        self.str_ = str(expression)

        if not isinstance(expression, list):
            expression = [expression]

        if not expression:
            self.expression = [True]
        elif len(expression) == 1:
            self.expression = expression
        elif len(expression) == 2:
            if expression[0] not in UNARY:
                raise ValueError(f"Invalid operator '{expression[0]}'")
            self.expression = expression
            expression[1] = Evaluator(expression[1])
        elif len(expression) == 3 and expression[1] != FN.OP_COMMA:
            if expression[1] not in BINARY:
                raise ValueError(f"Invalid operator '{expression[1]}'")
            self.expression = expression
            expression[0] = Evaluator(expression[0])
            expression[2] = Evaluator(expression[2])
        else:  # It's a list
            assert len(expression) % 2  # Must be odd length
            assert all(x == FN.OP_COMMA for i, x in enumerate(expression) if i % 2)
            self.expression = [Evaluator(x) if not i % 2 else x for i, x in enumerate(expression)]

    @staticmethod
    def normalize(value):
        """If a value is of type boolean converts it to string,
        returning "" for False, or the value to string for true.
        """
        if not value:
            return ""
        return str(value)

    def eval(self, vars_: Optional[Dict[str, Any]] = None) -> Union[str, Evaluator, List[Any]]:
        if vars_ is None:
            vars_ = {}

        if len(self.expression) == 1:
            val = self.expression[0]
            if not isinstance(val, str):
                return val
            if val == "$":
                return val
            if not RE_SVAR.match(val):
                return val
            if val not in vars_:
                raise UnboundVarError(f"Unbound variable '{val}'")
            return vars_[val]

        if len(self.expression) == 2:
            oper = self.expression[0]
            assert oper in UNARY
            operand = self.expression[1].eval(vars_)
            return self.normalize(UNARY[oper](operand))

        if len(self.expression) == 3 and self.expression[1] != FN.OP_COMMA:
            assert self.expression[1] in BINARY
            # Do lazy evaluation
            left_ = lambda: self.expression[0].eval(vars_)
            right_ = lambda: self.expression[2].eval(vars_)
            return self.normalize(BINARY[self.expression[1]](left_, right_))

        # It's a list
        return [x.eval(vars_) for i, x in enumerate(self.expression) if not i % 2]

    def __eq__(self, other):
        return self.expression == other.expression

    def __repr__(self):
        return self.str_
