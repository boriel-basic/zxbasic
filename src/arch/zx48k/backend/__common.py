#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim ts=4:et:sw=4:ai

import math

from typing import List
from typing import Set

import src.api.global_ as gl
import src.api.errors

from .runtime import RUNTIME_LABELS
from .runtime import LABEL_REQUIRED_MODULES


MEMORY = []  # Must be initialized by with init()

# Counter for generated labels (__LABEL0, __LABEL1, __LABELN...)
LABEL_COUNTER = 0

# Counter for generated tmp labels (__TMP0, __TMP1, __TMPN)
TMP_COUNTER = 0
TMP_STORAGES: List[str] = []

# Set containing REQUIRED libraries
REQUIRES: Set[str] = set()  # Set of required libraries (included once)

# Set containing automatic on start called routines
INITS: Set[str] = set()  # Set of INIT routines

# CONSTANT LN(2)
__LN2 = math.log(2)

# GENERATED labels __LABELXX
TMP_LABELS: Set[str] = set()


def init():
    global LABEL_COUNTER
    global TMP_COUNTER

    LABEL_COUNTER = 0
    TMP_COUNTER = 0

    del MEMORY[:]
    del TMP_STORAGES[:]
    REQUIRES.clear()
    INITS.clear()
    TMP_LABELS.clear()


def log2(x: float) -> float:
    """ Returns log2(x)
    """
    return math.log(x) / __LN2


def is_2n(x: float) -> bool:
    """ Returns true if x is an exact
    power of 2
    """
    if x < 1 or x != int(x):
        return False

    n = log2(x)
    return n == int(n)


def tmp_label() -> str:
    global LABEL_COUNTER
    global TMP_LABELS

    result = f'{gl.LABELS_NAMESPACE}.__LABEL{LABEL_COUNTER}'
    TMP_LABELS.add(result)
    LABEL_COUNTER += 1

    return result


def tmp_remove(label: str):
    if label not in TMP_STORAGES:
        raise src.api.errors.TempAlreadyFreedError(label)

    TMP_STORAGES.pop(TMP_STORAGES.index(label))


def runtime_call(label):
    assert label in RUNTIME_LABELS, f"Invalid runtime label '{label}'"
    if label in LABEL_REQUIRED_MODULES:
        REQUIRES.add(LABEL_REQUIRED_MODULES[label])

    return f'call {label}'


# ------------------------------------------------------------------
# Operands checking
# ------------------------------------------------------------------
def is_int(op):
    """ Returns True if the given operand (string)
    contains an integer number
    """
    try:
        int(op)
        return True

    except ValueError:
        pass

    return False


def is_float(op):
    """ Returns True if the given operand (string)
    contains a floating point number
    """
    try:
        float(op)
        return True

    except ValueError:
        pass

    return False


def _int_ops(op1, op2, swap=True):
    """ Receives a list with two strings (operands).
    If none of them contains integers, returns None.
    Otherwise, returns a t-uple with (op[0], op[1]),
    where op[1] is the integer one (the list is swapped)
    unless swap is False (e.g. sub and div used this
    because they're not commutative).

    The integer operand is always converted to int type.
    """
    if is_int(op1):
        if swap:
            return op2, int(op1)
        else:
            return int(op1), op2

    if is_int(op2):
        return op1, int(op2)

    return None


def _f_ops(op1, op2, swap=True):
    """ Receives a list with two strings (operands).
    If none of them contains integers, returns None.
    Otherwise, returns a t-uple with (op[0], op[1]),
    where op[1] is the integer one (the list is swapped)
    unless swap is False (e.g. sub and div used this
    because they're not commutative).

    The integer operand is always converted to int type.
    """
    if is_float(op1):
        if swap:
            return op2, float(op1)
        else:
            return float(op1), op2

    if is_float(op2):
        return op1, float(op2)

    return None
