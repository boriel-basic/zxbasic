#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim ts=4:et:sw=4:ai

import math
from .errors import TempAlreadyFreedError

MEMORY = []  # Must be initalized by init(MEM)

# Counter for generated labels (__LABEL0, __LABEL1, __LABELN...)
LABEL_COUNTER = 0

# Counter for generated tmp labels (__TMP0, __TMP1, __TMPN)
TMP_COUNTER = 0
TMP_STORAGES = []

# Set containing REQUIRED libraries
REQUIRES = set()  # Set of required libraries (included once)

# Set containing automatic on start called routines
INITS = set()  # Set of INIT routines

# CONSTANT LN(2)
__LN2 = math.log(2)

# GENERATED labels __LABELXX
TMP_LABELS = set()


def log2(x):
    """ Returns log2(x)
    """
    return math.log(x) / __LN2


def is_2n(x):
    """ Returns true if x is an exact
    power of 2
    """
    l = log2(x)
    return l == int(l)


def tmp_label():
    global LABEL_COUNTER
    global TMP_LABELS

    result = '__LABEL%i' % LABEL_COUNTER
    TMP_LABELS.add(result)
    LABEL_COUNTER += 1

    return result


def tmp_temp():
    global TMP_COUNTER

    for i in range(TMP_COUNTER):
        result = '__TEMP%i' % i

        if result not in TMP_STORAGES:
            TMP_STORAGES.append(result)
            return result
        
    result = '__TEMP%i' % TMP_COUNTER
    TMP_STORAGES.append(result)
    TMP_COUNTER += 1

    return result


def tmp_remove(label):
    if label not in TMP_STORAGES:
        raise TempAlreadyFreedError(label)

    TMP_STORAGES.pop(TMP_STORAGES.index(label))


# ------------------------------------------------------------------
# Operands checking
# ------------------------------------------------------------------
def is_int(op):
    """ Returns True if the given operand (string)
    contains an integer number
    """
    try:
        tmp = int(op)
        return True

    except ValueError:
        pass

    return False


def is_float(op):
    """ Returns True if the given operand (string)
    contains a floating point number
    """
    try:
        tmp = float(op)
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

