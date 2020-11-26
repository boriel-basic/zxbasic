# -*- coding: utf-8 -*-

import re

from src.api import utils
from .template import UnboundVarError
from .pattern import RE_SVAR
from ..optimizer import helpers
from ..optimizer import memcell

OP_NOT = '!'
OP_PLUS = '+'
OP_EQ = '=='
OP_NE = '<>'
OP_AND = '&&'
OP_OR = '||'
OP_IN = 'IN'
OP_COMMA = ','
OP_NPLUS = '.+'
OP_NSUB = '.-'
OP_NMUL = '.*'
OP_NDIV = './'

# Reg expr patterns
RE_IXIY_IDX = re.compile(r'^\([ \t]*i[xy][ \t]*[-+][ \t]*.+\)$')


# Unary functions and operators
UNARY = {
    OP_NOT: lambda x: not x,
    'IS_ASM': lambda x: x.startswith('##ASM'),
    'IS_INDIR': lambda x: RE_IXIY_IDX.match(x),
    'IS_REG16': lambda x: x.strip().lower() in ('af', 'bc', 'de', 'hl', 'ix', 'iy'),
    'IS_REG8': lambda x: x.strip().lower() in ('a', 'b', 'c', 'd', 'e', 'h', 'l', 'ixh', 'ixl', 'iyh', 'iyl'),
    'IS_LABEL': lambda x: x.strip()[-1:] == ':',
    'LEN': lambda x: str(len(x.split())),
    'INSTR': lambda x: x.strip().split()[0],
    'HIREG': lambda x: {
        'af': 'a',
        'bc': 'b',
        'de': 'd',
        'hl': 'h',
        'ix': 'ixh',
        'iy': 'iyh'}.get(x.strip().lower(), ''),
    'LOREG': lambda x: {
        'af': 'f',
        'bc': 'c',
        'de': 'e',
        'hl': 'l',
        'ix': 'ixl',
        'iy': 'iyl'}.get(x.strip().lower(), ''),
    'HIVAL': helpers.HI16_val,
    'LOVAL': helpers.LO16_val,
    'GVAL': lambda x: helpers.new_tmp_val(),  # To be updated in the O3 optimizer
    'IS_REQUIRED': lambda x: True,  # by default always required
    'CTEST': lambda x: memcell.MemCell(x, 1).condition_flag,  # condition test, if any. E.g. retz returns 'z'
    'NEEDS': lambda x: memcell.MemCell(x[0], 1).needs(x[1]),
    'FLAGVAL': lambda x: helpers.new_tmp_val()
}

# Binary operators
BINARY = {
    OP_EQ: lambda x, y: x() == y(),
    OP_PLUS: lambda x, y: x() + y(),
    OP_NE: lambda x, y: x() != y(),
    OP_AND: lambda x, y: x() and y(),
    OP_OR: lambda x, y: x() or y(),
    OP_IN: lambda x, y: x() in y(),
    OP_COMMA: lambda x, y: [x(), y()],
    OP_NPLUS: lambda x, y: str(Number(x()) + Number(y())),
    OP_NSUB: lambda x, y: str(Number(x()) - Number(y())),
    OP_NMUL: lambda x, y: str(Number(x()) * Number(y())),
    OP_NDIV: lambda x, y: str(Number(x()) / Number(y()))
}

OPERS = set(BINARY.keys()).union(UNARY.keys())


class Number(object):
    """ Emulates a number that can be also None
    """
    def __init__(self, value):
        if isinstance(value, Number):
            value = value.value
        self.value = utils.parse_int(str(value))

    def __repr__(self):
        return str(self.value) if self.value is not None else ''

    def __str__(self):
        return repr(self)

    def __add__(self, other):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number('')
        return Number(self.value + other.value)

    def __sub__(self, other):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number('')
        return Number(self.value - other.value)

    def __mul__(self, other):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number('')
        return Number(self.value * other.value)

    def __floordiv__(self, other):
        assert isinstance(other, Number)
        if self.value is None or other.value is None:
            return Number('')
        if not other.value:
            return None  # Div by Zero
        return Number(self.value / other.value)

    def __truediv__(self, other):
        return self.__floordiv__(other)


class Evaluator(object):
    """ Evaluates a given expression, which comes as an AST in nested lists. For example:
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
    UNARY = dict(UNARY)
    BINARY = dict(BINARY)

    def __init__(self, expression, unary=None, binary=None):
        """ Initializes the object parsing the expression and preparing it for its (later)
        execution.
        :param expression: An expression (an AST in nested list parsed from the parser module
        :param unary: optional dict of unary functions (defaults to UNARY)
        :param binary: optional dict of binary operators (defaults to BINARY)
        """
        self.str_ = str(expression)
        self.unary = unary if unary is not None else Evaluator.UNARY
        self.binary = binary if binary is not None else Evaluator.BINARY

        if not isinstance(expression, list):
            expression = [expression]

        if not expression:
            self.expression = [True]
        elif len(expression) == 1:
            self.expression = expression
        elif len(expression) == 2:
            if expression[0] not in self.unary:
                raise ValueError("Invalid operator '{0}'".format(expression[0]))
            self.expression = expression
            expression[1] = Evaluator(expression[1])
        elif len(expression) == 3 and expression[1] != OP_COMMA:
            if expression[1] not in self.binary:
                raise ValueError("Invalid operator '{0}'".format(expression[1]))
            self.expression = expression
            expression[0] = Evaluator(expression[0])
            expression[2] = Evaluator(expression[2])
        else:  # It's a list
            assert len(expression) % 2  # Must be odd length
            assert all(x == OP_COMMA for i, x in enumerate(expression) if i % 2)
            self.expression = [Evaluator(x) if not i % 2 else x for i, x in enumerate(expression)]

    def normalize(self, value):
        """ If a value is of type boolean converts it to string,
        returning "" for False, or the value to string for true.
        """
        if not value:
            return ""
        return str(value)

    def eval(self, vars_=None):
        if vars_ is None:
            vars_ = {}

        if len(self.expression) == 1:
            val = self.expression[0]
            if not isinstance(val, str):
                return val
            if val == '$':
                return val
            if not RE_SVAR.match(val):
                return val
            if val not in vars_:
                raise UnboundVarError("Unbound variable '{0}'".format(val))
            return vars_[val]

        if len(self.expression) == 2:
            oper = self.expression[0]
            assert oper in self.unary
            operand = self.expression[1].eval(vars_)
            return self.normalize(self.unary[oper](operand))

        if len(self.expression) == 3 and self.expression[1] != OP_COMMA:
            assert self.expression[1] in self.binary
            # Do lazy evaluation
            left_ = lambda: self.expression[0].eval(vars_)
            right_ = lambda: self.expression[2].eval(vars_)
            return self.normalize(self.binary[self.expression[1]](left_, right_))

        # It's a list
        return [x.eval(vars_) for i, x in enumerate(self.expression) if not i % 2]

    def __eq__(self, other):
        return self.expression == other.expression

    def __repr__(self):
        return self.str_
