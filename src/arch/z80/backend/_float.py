# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import fp
from src.arch.interface.quad import Quad
from src.arch.z80.backend.common import _f_ops, is_float, is_int, runtime_call
from src.arch.z80.backend.runtime import RUNTIME_LABELS
from src.arch.z80.backend.runtime import Labels as RuntimeLabel


class Float:
    @classmethod
    def float(cls, op: str | int | float) -> tuple[str, str, str]:
        """Returns a floating point operand converted to 5 byte (40 bits) unsigned int.
        The result is returned in a tuple (C, DE, HL) => Exp, mantissa =>High16 (Int part), Low16 (Decimal part)
        """
        return fp.immediate_float(float(op))

    @classmethod
    def fpop(cls) -> list[str]:
        """Returns the pop sequence of a float"""
        return [
            "pop af",
            "pop de",
            "pop bc",
        ]

    @classmethod
    def fpush(cls) -> list[str]:
        """Returns the push sequence of a float"""
        return [
            "push bc",
            "push de",
            "push af",
        ]

    @classmethod
    def get_oper(cls, op1: str, op2: str | None = None) -> list[str]:
        """Returns pop sequence for floating point operands
        1st operand in A DE BC, 2nd operand remains in the stack

        Unlike 8bit and 16bit version, this does not support
        operands inversion. Since many of the instructions are implemented
        as functions, they must support this.

        However, if 1st operand is a number (immediate) or indirect, the stack
        will be rearranged, so it contains a 48 bit pushed parameter value for the
        subroutine to be called.
        """
        output = []
        op = op2 if op2 is not None else op1

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        if is_float(op):
            op = float(op)

            if indirect:
                op = int(op) & 0xFFFF
                output.append(f"ld hl, ({op})")
                output.append(runtime_call(RuntimeLabel.ILOADF))
            else:
                A, DE, BC = cls.float(op)
                output.append("ld a, %s" % A)
                output.append("ld de, %s" % DE)
                output.append("ld bc, %s" % BC)
        else:
            if indirect:
                if op[0] == "_":
                    output.append("ld hl, (%s)" % op)
                else:
                    output.append("pop hl")

                output.append(runtime_call(RuntimeLabel.LOADF))
            else:
                if op[0] == "_":
                    output.append("ld a, (%s)" % op)
                    output.append("ld de, (%s + 1)" % op)
                    output.append("ld bc, (%s + 3)" % op)
                else:
                    output.extend(cls.fpop())

        if op2 is not None:
            op = op1
            if is_float(op):  # A float must be in the stack. Let's push it
                A, DE, BC = cls.float(op)
                output.append("ld hl, %s" % BC)
                output.append("push hl")
                output.append("ld hl, %s" % DE)
                output.append("push hl")
                output.append("ld h, %s" % A)
                output.append("push hl")
            elif op[0] == "*":  # Indirect
                op = op[1:]
                output.append("exx")  # uses alternate set to put it on the stack
                output.append("ex af, af'")
                if is_int(op):  # TODO: it will fail
                    op = int(op)
                    output.append(f"ld hl, {op}")
                elif op[0] == "_":
                    output.append(f"ld hl, ({op})")
                else:
                    output.append("pop hl")

                output.append(runtime_call(RuntimeLabel.ILOADF))
                output.extend(cls.fpush())
                output.append("ex af, af'")
                output.append("exx")
            elif op[0] == "_":
                if is_float(op2):
                    tmp = output
                    output = []
                    output.append("ld hl, %s + 4" % op)
                    output.append(runtime_call(RuntimeLabel.FP_PUSH_REV))
                    output.extend(tmp)
                else:
                    output.append("ld hl, %s + 4" % op)
                    output.append(runtime_call(RuntimeLabel.FP_PUSH_REV))
            else:
                pass  # Else do nothing, and leave the op onto the stack

        return output

    # -----------------------------------------------------
    #               Arithmetic operations
    # -----------------------------------------------------

    @classmethod
    def float_binary(cls, ins: Quad, label: str) -> list[str]:
        assert label in RUNTIME_LABELS

        op1, op2 = tuple(ins[2:])
        output = cls.get_oper(op1, op2)
        output.append(runtime_call(label))
        output.extend(cls.fpush())
        return output

    @classmethod
    def addf(cls, ins: Quad) -> list[str]:
        """Add 2 float values. The result is pushed onto the stack."""
        op1, op2 = tuple(ins[2:])

        # TODO: This should be done in the optimizer
        if _f_ops(op1, op2) is not None:
            opa, opb = _f_ops(op1, op2)
            if opb == 0:  # A + 0 => A
                output = cls.get_oper(opa)
                output.extend(cls.fpush())
                return output

        return cls.float_binary(ins, RuntimeLabel.ADDF)

    @classmethod
    def subf(cls, ins: Quad) -> list[str]:
        """Subtract 2 float values. The result is pushed onto the stack."""
        op1, op2 = tuple(ins[2:])

        # TODO: This should be done in the optimizer
        if is_float(op2) and float(op2) == 0:  # Nothing to do: A - 0 = A
            output = cls.get_oper(op1)
            output.extend(cls.fpush())
            return output

        return cls.float_binary(ins, RuntimeLabel.SUBF)

    @classmethod
    def mulf(cls, ins: Quad) -> list[str]:
        """Multiply 2 float values. The result is pushed onto the stack."""
        op1, op2 = tuple(ins[2:])

        # TODO: This should be done in the optimizer
        if _f_ops(op1, op2) is not None:
            opa, opb = _f_ops(op1, op2)
            if opb == 1:  # A * 1 => A
                output = cls.get_oper(opa)
                output.extend(cls.fpush())
                return output

        return cls.float_binary(ins, RuntimeLabel.MULF)

    @classmethod
    def divf(cls, ins: Quad) -> list[str]:
        """Divide 2 float values. The result is pushed onto the stack."""
        op1, op2 = tuple(ins[2:])

        # TODO: This should be done in the optimizer
        if is_float(op2) and float(op2) == 1:  # Nothing to do. A / 1 = A
            output = cls.get_oper(op1)
            output.extend(cls.fpush())
            return output

        return cls.float_binary(ins, RuntimeLabel.DIVF)

    @classmethod
    def modf(cls, ins: Quad) -> list[str]:
        """Reminder of div. 2 float values. The result is pushed onto the stack."""
        return cls.float_binary(ins, RuntimeLabel.MODF)

    @classmethod
    def powf(cls, ins: Quad) -> list[str]:
        """Exponentiation of 2 float values. The result is pushed onto the stack."""
        op1, op2 = tuple(ins[2:])

        # TODO: This should be done in the optimizer
        if is_float(op2) and float(op2) == 1:  # Nothing to do. A ^ 1 = A
            output = cls.get_oper(op1)
            output.extend(cls.fpush())
            return output

        return cls.float_binary(ins, RuntimeLabel.POWF)

    @classmethod
    def bool_binary(cls, ins: Quad, label: str) -> list[str]:
        assert label in RUNTIME_LABELS
        op1, op2 = tuple(ins[2:])
        output = cls.get_oper(op1, op2)
        output.append(runtime_call(label))
        output.append("push af")
        return output

    @classmethod
    def ltf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.LTF)

    @classmethod
    def gtf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.GTF)

    @classmethod
    def lef(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.LEF)

    @classmethod
    def gef(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.GEF)

    @classmethod
    def eqf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.EQF)

    @classmethod
    def nef(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.NEF)

    @classmethod
    def orf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand || 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.ORF)

    @classmethod
    def xorf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand ~~ 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.XORF)

    @classmethod
    def andf(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand && 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        Floating Point version
        """
        return cls.bool_binary(ins, RuntimeLabel.ANDF)

    @classmethod
    def notf(cls, ins: Quad) -> list[str]:
        """Negates top of the stack (48 bits)"""
        output = cls.get_oper(ins[2])
        output.append(runtime_call(RuntimeLabel.NOTF))
        output.append("push af")
        return output

    @classmethod
    def negf(cls, ins: Quad) -> list[str]:
        """Changes sign of top of the stack (48 bits)"""
        output = cls.get_oper(ins[2])
        output.append(runtime_call(RuntimeLabel.NEGF))
        output.extend(cls.fpush())
        return output

    @classmethod
    def absf(cls, ins: Quad) -> list[str]:
        """Absolute value of top of the stack (48 bits)"""
        output = cls.get_oper(ins[2])
        output.append("res 7, e")  # Just resets the sign bit!
        output.extend(cls.fpush())
        return output

    @classmethod
    def loadf(cls, ins: Quad) -> list[str]:
        """Loads a floating point value from a memory address.
        If 2nd arg. start with '*', it is always treated as
        an indirect value.
        """
        output = cls.get_oper(ins[2])
        output.extend(cls.fpush())
        return output

    @classmethod
    def storef(cls, ins: Quad) -> list[str]:
        """Stores a floating point value into a memory address."""
        output = cls.get_oper(ins[2])

        op = ins[1]

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"  # Might make no sense here?
        if immediate:
            op = op[1:]

        if is_int(op) or op[0] in "_.":
            if is_int(op):
                op = str(int(op) & 0xFFFF)

            if indirect:
                output.append("ld hl, (%s)" % op)
            else:
                output.append("ld hl, %s" % op)
        else:
            output.append("pop hl")
            if indirect:
                output.append(runtime_call(RuntimeLabel.ISTOREF))
                # TODO: Check if this is ever used
                return output

        output.append(runtime_call(RuntimeLabel.STOREF))

        return output

    @classmethod
    def jzerof(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (40bit, float) is 0 to arg(1)"""
        value = ins[1]
        if is_float(value):
            if float(value) == 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("ld a, c")
        output.append("or l")
        output.append("or h")
        output.append("or e")
        output.append("or d")
        output.append("jp z, %s" % str(ins[2]))
        return output

    @classmethod
    def jnzerof(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (40bit, float) is != 0 to arg(1)"""
        value = ins[1]
        if is_float(value):
            if float(value) != 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("ld a, c")
        output.append("or l")
        output.append("or h")
        output.append("or e")
        output.append("or d")
        output.append("jp nz, %s" % str(ins[2]))
        return output

    @classmethod
    def jgezerof(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (40bit, float) is >= 0 to arg(1)"""
        value = ins[1]
        if is_float(value):
            if float(value) >= 0:
                return ["jp %s" % str(ins[2])]  # Always true

        output = cls.get_oper(value)
        output.append("ld a, e")  # Take sign from mantissa (bit 7)
        output.append("add a, a")  # Puts sign into carry
        output.append("jp nc, %s" % str(ins[2]))
        return output

    @classmethod
    def retf(cls, ins: Quad) -> list[str]:
        """Returns from a procedure / function a Floating Point (40bits) value"""
        output = cls.get_oper(ins[1])
        output.append("#pragma opt require a,bc,de")
        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def paramf(cls, ins: Quad) -> list[str]:
        """Pushes 40bit (float) param into the stack"""
        output = cls.get_oper(ins[1])
        output.extend(cls.fpush())
        return output

    @classmethod
    def fparamf(cls, ins: Quad) -> list[str]:
        """Passes a floating point as a __FASTCALL__ parameter.
        This is done by popping out of the stack for a
        value, or by loading it from memory (indirect)
        or directly (immediate)
        """
        return cls.get_oper(ins[1])
