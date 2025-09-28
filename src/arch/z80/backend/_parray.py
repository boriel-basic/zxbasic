# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import fp

from . import common
from ._f16 import Fixed16
from ._float import Float
from .common import runtime_call
from .quad import Quad
from .runtime import Labels as RuntimeLabel


def _paddr(offset) -> list[str]:
    """Generic element array-address stack-ptr loading.
    Emits output code for setting IX at the right location.
    bytes = Number of bytes to load:
        1 => 8 bit value
        2 => 16 bit value / string
        4 => 32 bit value / f16 value
        5 => 40 bit value
    """
    output = []

    indirect = offset[0] == "*"
    if indirect:
        offset = offset[1:]

    i = int(offset)
    if i >= 0:
        i += 4  # Return Address + "push IX"

    output.append(f"push {common.IDX_REG}")
    output.append("pop hl")
    output.append("ld de, %i" % i)
    output.append("add hl, de")

    if indirect:
        output.append(runtime_call(RuntimeLabel.ARRAY_PTR))
    else:
        output.append(runtime_call(RuntimeLabel.ARRAY))

    return output


def _paaddr(ins: Quad) -> list[str]:
    """Loads address of an array element into the stack"""
    output = _paddr(ins[2])
    output.append("push hl")

    return output


def _paload8(ins: Quad) -> list[str]:
    """Loads an 8 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _paddr(ins[2])
    output.append("ld a, (hl)")
    output.append("push af")

    return output


def _paload16(ins: Quad) -> list[str]:
    """Loads a 16 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _paddr(ins[2])

    output.append("ld e, (hl)")
    output.append("inc hl")
    output.append("ld d, (hl)")
    output.append("ex de, hl")
    output.append("push hl")

    return output


def _paload32(ins: Quad) -> list[str]:
    """Loads a 32 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _paddr(ins[2])

    output.append(runtime_call(RuntimeLabel.ILOAD32))
    output.append("push de")
    output.append("push hl")

    return output


def _paloadf(ins: Quad) -> list[str]:
    """Loads a floating point value from a memory address."""
    output = _paddr(ins[2])

    output.append(runtime_call(RuntimeLabel.LOADF))
    output.extend(Float.fpush())

    return output


def _paloadstr(ins: Quad) -> list[str]:
    """Loads a string value from a memory address."""
    output = _paddr(ins[2])

    output.append(runtime_call(RuntimeLabel.ILOADSTR))
    output.append("push hl")

    return output


def _pastore8(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    1st operand is an array element. Dimensions are pushed into the
    stack.
    Use '*' for indirect store on 1st operand (A pointer to an array)
    """
    output = _paddr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(value) & 0xFFFF
        if indirect:
            output.append("ld a, (%i)" % value)
            output.append("ld (hl), a")
        else:
            value &= 0xFF
            output.append("ld (hl), %i" % value)
    except ValueError:
        output.append("pop af")
        output.append("ld (hl), a")

    return output


def _pastore16(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    Use '*' for indirect store on 1st operand.
    """
    output = _paddr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(value) & 0xFFFF
        output.append("ld de, %i" % value)
        if indirect:
            output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))

    except ValueError:
        output.append("pop de")

    output.append("ld (hl), e")
    output.append("inc hl")
    output.append("ld (hl), d")

    return output


def _pastore32(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    """
    output = _paddr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(value) & 0xFFFFFFFF  # Immediate?
        if indirect:
            output.append("push hl")
            output.append("ld hl, %i" % (value & 0xFFFF))
            output.append(runtime_call(RuntimeLabel.ILOAD32))
            output.append("ld b, h")
            output.append("ld c, l")  # BC = Lower 16 bits
            output.append("pop hl")
        else:
            output.append("ld de, %i" % (value >> 16))
            output.append("ld bc, %i" % (value & 0xFFFF))
    except ValueError:
        output.append("pop bc")
        output.append("pop de")

    output.append(runtime_call(RuntimeLabel.STORE32))
    return output


def _pastoref16(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    storef16 a, x =>  *(&a) = x
    """
    output = _paddr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        if indirect:
            value = int(ins[2])
            output.append("push hl")
            output.append("ld hl, %i" % (value & 0xFFFF))
            output.append(runtime_call(RuntimeLabel.ILOAD32))
            output.append("ld b, h")
            output.append("ld c, l")  # BC = Lower 16 bits
            output.append("pop hl")
        else:
            de, hl = Fixed16.f16(value)
            output.append("ld de, %i" % de)
            output.append("ld bc, %i" % hl)
    except ValueError:
        output.append("pop bc")
        output.append("pop de")

    output.append(runtime_call(RuntimeLabel.STORE32))
    return output


def _pastoref(ins: Quad) -> list[str]:
    """Stores a floating point value into a memory address."""
    output = _paddr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        if indirect:
            value = int(value) & 0xFFFF  # Immediate?
            output.append("push hl")
            output.append("ld hl, %i" % value)
            output.append(runtime_call(RuntimeLabel.ILOADF))
            output.append("ld a, c")
            output.append("ld b, h")
            output.append("ld c, l")  # BC = Lower 16 bits, A = Exp
            output.append("pop hl")  # Recovers pointer
        else:
            value = float(value)  # Immediate?
            C, DE, HL = fp.immediate_float(value)
            output.append("ld a, %s" % C)
            output.append("ld de, %s" % DE)
            output.append("ld bc, %s" % HL)
    except ValueError:
        output.append("pop bc")
        output.append("pop de")
        output.append("ex (sp), hl")  # Preserve HL for STOREF
        output.append("ld a, l")
        output.append("pop hl")

    output.append(runtime_call(RuntimeLabel.STOREF))
    return output


def _pastorestr(ins: Quad) -> list[str]:
    """Stores a string value into a memory address.
    It copies content of 2nd operand (string), into 1st, reallocating
    dynamic memory for the 1st str. These instruction DOES ALLOW
    immediate strings for the 2nd parameter, starting with '#'.
    """
    output = _paddr(ins[1])
    temporal = False
    value = ins[2]

    indirect = value[0] == "*"
    if indirect:
        value = value[1:]

    immediate = value[0]
    if immediate:
        value = value[1:]

    if value[0] == "_":
        if indirect:
            if immediate:
                output.append("ld de, (%s)" % value)
            else:
                output.append("ld de, (%s)" % value)
                output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))
        else:
            if immediate:
                output.append("ld de, %s" % value)
            else:
                output.append("ld de, (%s)" % value)
    else:
        output.append("pop de")
        temporal = True

        if indirect:
            output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))

    if not temporal:
        output.append(runtime_call(RuntimeLabel.STORE_STR))
    else:  # A value already on dynamic memory
        output.append(runtime_call(RuntimeLabel.STORE_STR2))

    return output
