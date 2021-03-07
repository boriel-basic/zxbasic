#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparison intermediate-code translations
# --------------------------------------------------------------

from typing import List

from .__common import is_float, _f_ops
from .__common import runtime_call
from .runtime import Labels as RuntimeLabel
from .runtime import RUNTIME_LABELS

# -----------------------------------------------------
# Floating Point operators
# -----------------------------------------------------
from src.api import fp


def _float(op):
    """ Returns a floating point operand converted to 5 byte (40 bits) unsigned int.
    The result is returned in a tuple (C, DE, HL) => Exp, mantissa =>High16 (Int part), Low16 (Decimal part)
    """
    return fp.immediate_float(float(op))


def _fpop():
    """ Returns the pop sequence of a float
    """
    output = [
        'pop af',
        'pop de',
        'pop bc'
    ]

    return output


def _fpush():
    """ Returns the push sequence of a float
    """
    output = [
        'push bc',
        'push de',
        'push af'
    ]

    return output


def _float_oper(op1, op2=None):
    """ Returns pop sequence for floating point operands
    1st operand in A DE BC, 2nd operand remains in the stack

    Unlike 8bit and 16bit version, this does not supports
    operands inversion. Since many of the instructions are implemented
    as functions, they must support this.

    However, if 1st operand is a number (immediate) or indirect, the stack
    will be rearranged, so it contains a 48 bit pushed parameter value for the
    subroutine to be called.
    """
    output = []
    op = op2 if op2 is not None else op1

    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    if is_float(op):
        op = float(op)

        if indirect:
            op = int(op) & 0xFFFF
            output.append('ld hl, (%i)' % op)
            output.append(runtime_call(RuntimeLabel.ILOADF))
        else:
            A, DE, BC = _float(op)
            output.append('ld a, %s' % A)
            output.append('ld de, %s' % DE)
            output.append('ld bc, %s' % BC)
    else:
        if indirect:
            if op[0] == '_':
                output.append('ld hl, (%s)' % op)
            else:
                output.append('pop hl')

            output.append(runtime_call(RuntimeLabel.ILOADF))
        else:
            if op[0] == '_':
                output.append('ld a, (%s)' % op)
                output.append('ld de, (%s + 1)' % op)
                output.append('ld bc, (%s + 3)' % op)
            else:
                output.extend(_fpop())

    if op2 is not None:
        op = op1
        if is_float(op):  # An float must be in the stack. Let's push it
            A, DE, BC = _float(op)
            output.append('ld hl, %s' % BC)
            output.append('push hl')
            output.append('ld hl, %s' % DE)
            output.append('push hl')
            output.append('ld h, %s' % A)
            output.append('push hl')
        elif op[0] == '*':  # Indirect
            op = op[1:]
            output.append('exx')  # uses alternate set to put it on the stack
            output.append("ex af, af'")
            if is_int(op):  # noqa TODO: it will fail
                op = int(op)
                output.append('ld hl, %i' % op)
            elif op[0] == '_':
                output.append('ld hl, (%s)' % op)
            else:
                output.append('pop hl')

            output.append(runtime_call(RuntimeLabel.ILOADF))
            output.extend(_fpush())
            output.append("ex af, af'")
            output.append('exx')
        elif op[0] == '_':
            if is_float(op2):
                tmp = output
                output = []
                output.append('ld hl, %s + 4' % op)
                output.append(runtime_call(RuntimeLabel.FP_PUSH_REV))
                output.extend(tmp)
            else:
                output.append('ld hl, %s + 4' % op)
                output.append(runtime_call(RuntimeLabel.FP_PUSH_REV))
        else:
            pass  # Else do nothing, and leave the op onto the stack

    return output


# -----------------------------------------------------
#               Arithmetic operations
# -----------------------------------------------------

def __float_binary(ins, label: str) -> List[str]:
    assert label in RUNTIME_LABELS

    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append(runtime_call(label))
    output.extend(_fpush())
    return output


def _addf(ins):
    """ Add 2 float values. The result is pushed onto the stack.
    """
    op1, op2 = tuple(ins.quad[2:])

    # TODO: This should be done in the optimizer
    if _f_ops(op1, op2) is not None:
        opa, opb = _f_ops(op1, op2)
        if opb == 0:  # A + 0 => A
            output = _float_oper(opa)
            output.extend(_fpush())
            return output

    return __float_binary(ins, RuntimeLabel.ADDF)


def _subf(ins):
    """ Subtract 2 float values. The result is pushed onto the stack.
    """
    op1, op2 = tuple(ins.quad[2:])

    # TODO: This should be done in the optimizer
    if is_float(op2) and float(op2) == 0:  # Nothing to do: A - 0 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    return __float_binary(ins, RuntimeLabel.SUBF)


def _mulf(ins):
    """ Multiply 2 float values. The result is pushed onto the stack.
    """
    op1, op2 = tuple(ins.quad[2:])

    # TODO: This should be done in the optimizer
    if _f_ops(op1, op2) is not None:
        opa, opb = _f_ops(op1, op2)
        if opb == 1:  # A * 1 => A
            output = _float_oper(opa)
            output.extend(_fpush())
            return output

    return __float_binary(ins, RuntimeLabel.MULF)


def _divf(ins):
    """ Divide 2 float values. The result is pushed onto the stack.
    """
    op1, op2 = tuple(ins.quad[2:])

    # TODO: This should be done in the optimizer
    if is_float(op2) and float(op2) == 1:  # Nothing to do. A / 1 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    return __float_binary(ins, RuntimeLabel.DIVF)


def _modf(ins):
    """ Reminder of div. 2 float values. The result is pushed onto the stack.
    """
    return __float_binary(ins, RuntimeLabel.MODF)


def _powf(ins):
    """ Exponentiation of 2 float values. The result is pushed onto the stack.
    """
    op1, op2 = tuple(ins.quad[2:])

    # TODO: This should be done in the optimizer
    if is_float(op2) and float(op2) == 1:  # Nothing to do. A ^ 1 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    return __float_binary(ins, RuntimeLabel.POWF)


def __bool_binary(ins, label: str) -> List[str]:
    assert label in RUNTIME_LABELS
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append(runtime_call(label))
    output.append('push af')
    return output


def _ltf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.LTF)


def _gtf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.GTF)


def _lef(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.LEF)


def _gef(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.GEF)


def _eqf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.EQF)


def _nef(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.NEF)


def _orf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand || 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.ORF)


def _xorf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand ~~ 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.XORF)


def _andf(ins):
    """ Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand && 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
    """
    return __bool_binary(ins, RuntimeLabel.ANDF)


def _notf(ins):
    """ Negates top of the stack (48 bits)
    """
    output = _float_oper(ins.quad[2])
    output.append(runtime_call(RuntimeLabel.NOTF))
    output.append('push af')
    return output


def _negf(ins):
    """ Changes sign of top of the stack (48 bits)
    """
    output = _float_oper(ins.quad[2])
    output.append(runtime_call(RuntimeLabel.NEGF))
    output.extend(_fpush())
    return output


def _absf(ins):
    """ Absolute value of top of the stack (48 bits)
    """
    output = _float_oper(ins.quad[2])
    output.append('res 7, e')  # Just resets the sign bit!
    output.extend(_fpush())
    return output
