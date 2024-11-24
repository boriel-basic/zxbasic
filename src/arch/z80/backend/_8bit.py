# vim: ts=4:sw=4:et

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparison intermediate-code translations
# --------------------------------------------------------------

from src.api.tmp_labels import tmp_label
from src.arch.interface.quad import Quad

from .common import _int_ops, is_2n, is_int, runtime_call
from .runtime import Labels as RuntimeLabel


class Bits8:
    """Implementation of 8bit (u8, i8) operations."""

    @classmethod
    def int8(cls, op: str | int) -> int:
        """Returns the operator converted to 8 bit unsigned integer (byte).
        For signed ones, it returns the 8bit C2 (Two Complement)
        """
        return int(op) & 0xFF

    @classmethod
    def get_oper(cls, op1: str, op2: str | None = None, *, reversed_: bool = False) -> list[str]:
        """Returns pop sequence for 8 bits operands
        1st operand in H, 2nd operand in A (accumulator)

        For some operations (like comparisons), you can swap
        operands extraction by setting reversed = True
        """
        output = []

        if op2 is not None and reversed_:
            op1, op2 = op2, op1

        op = op1
        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"
        if immediate:
            op = op[1:]

        if is_int(op):
            op_ = int(op)

            if indirect:
                output.append(f"ld a, ({op_})")
            else:
                if op_ == 0:
                    output.append("xor a")
                else:
                    output.append(f"ld a, {cls.int8(op_)}")
        else:
            if immediate:
                if indirect:
                    output.append("ld a, (%s)" % op)
                else:
                    output.append("ld a, %s" % op)
            elif op[0] == "_":
                if indirect:
                    idx = "bc" if reversed_ else "hl"
                    output.append("ld %s, (%s)" % (idx, op))  # can't use HL
                    output.append("ld a, (%s)" % idx)
                else:
                    output.append("ld a, (%s)" % op)
            else:
                if immediate:
                    output.append("ld a, %s" % op)
                elif indirect:
                    idx = "bc" if reversed_ else "hl"
                    output.append("pop %s" % idx)
                    output.append("ld a, (%s)" % idx)
                else:
                    output.append("pop af")

        if op2 is None:
            return output

        if not reversed_:
            tmp = output
            output = []

        op = op2
        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"
        if immediate:
            op = op[1:]

        if is_int(op):
            op_ = int(op)

            if indirect:
                output.append("ld hl, (%i - 1)" % op_)
            else:
                output.append("ld h, %i" % cls.int8(op_))
        else:
            if immediate:
                if indirect:
                    output.append("ld hl, %s" % op)
                    output.append("ld h, (hl)")
                else:
                    output.append("ld h, %s" % op)
            elif op[0] == "_":
                if indirect:
                    output.append("ld hl, (%s)" % op)
                    output.append("ld h, (hl)")  # TODO: Is this ever executed?
                else:
                    output.append("ld hl, (%s - 1)" % op)
            else:
                output.append("pop hl")

            if indirect:
                output.append("ld h, (hl)")

        if not reversed_:
            output.extend(tmp)

        return output

    @classmethod
    def add8(cls, ins: Quad) -> list[str]:
        """Pops last 2 bytes from the stack and adds them.
        Then push the result onto the stack.

        Optimizations:
          * If any of the operands is ZERO,
            then do NOTHING: A + 0 = 0 + A = A

          * If any of the operands is 1, then
            INC is used

          * If any of the operands is -1 (255), then
            DEC is used
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)
            if op2 == 0:  # Nothing to add: A + 0 = A
                output.append("push af")
                return output

            op2 = cls.int8(op2)

            if op2 == 1:  # Adding 1 is just an inc
                output.append("inc a")
                output.append("push af")
                return output

            if op2 == 0xFF:  # Adding 255 is just a dec
                output.append("dec a")
                output.append("push af")
                return output

            output.append("add a, %i" % cls.int8(op2))
            output.append("push af")
            return output

        if op2[0] == "_":  # stack optimization
            op1, op2 = op2, op1

        output = cls.get_oper(op1, op2)
        output.append("add a, h")
        output.append("push af")

        return output

    @classmethod
    def sub8(cls, ins: Quad) -> list[str]:
        """Pops last 2 bytes from the stack and subtract them.
        Then push the result onto the stack. Top-1 of the stack is
        subtracted Top
        _sub8 t1, a, b === t1 <-- a - b

        Optimizations:
          * If 2nd op is ZERO,
            then do NOTHING: A - 0 = A

          * If 1st operand is 0, then
            just do a NEG

          * If any of the operands is 1, then
            DEC is used

          * If any of the operands is -1 (255), then
            INC is used
        """

        op1, op2 = tuple(ins[2:])
        if is_int(op2):  # 2nd operand
            op2 = cls.int8(op2)
            output = cls.get_oper(op1)

            if op2 == 0:
                output.append("push af")
                return output  # A - 0 = A

            op2 = cls.int8(op2)

            if op2 == 1:  # A - 1 == DEC A
                output.append("dec a")
                output.append("push af")
                return output

            if op2 == 0xFF:  # A - (-1) == INC A
                output.append("inc a")
                output.append("push af")
                return output

            output.append("sub %i" % op2)
            output.append("push af")
            return output

        if is_int(op1):  # 1st operand is numeric?
            if cls.int8(op1) == 0:  # 0 - A = -A ==> NEG A
                output = cls.get_oper(op2)
                output.append("neg")
                output.append("push af")
                return output

        # At this point, even if 1st operand is numeric, proceed
        # normally

        if op2[0] == "_":  # Optimization when 2nd operand is an id
            rev = True
            op1, op2 = op2, op1
        else:
            rev = False

        output = cls.get_oper(op1, op2, reversed_=rev)
        output.append("sub h")
        output.append("push af")

        return output

    @classmethod
    def mul8(cls, ins: Quad) -> list[str]:
        """Multiplies 2 las values from the stack.

        Optimizations:
          * If any of the ops is ZERO,
            then do A = 0 ==> XOR A, cause A * 0 = 0 * A = 0

          * If any ot the ops is ONE, do NOTHING
            A * 1 = 1 * A = A
        """

        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)

            if op2 == 0:
                output.append("xor a")
                output.append("push af")
                return output

            if op2 == 1:  # A * 1 = 1 * A = A
                output.append("push af")
                return output

            if op2 == 2:  # A * 2 == A SLA 1
                output.append("add a, a")
                output.append("push af")
                return output

            if op2 == 4:  # A * 4 == A SLA 2
                output.append("add a, a")
                output.append("add a, a")
                output.append("push af")
                return output

            output.append("ld h, %i" % cls.int8(op2))
        else:
            if op2[0] == "_":  # stack optimization
                op1, op2 = op2, op1

            output = cls.get_oper(op1, op2)

        output.append(runtime_call(RuntimeLabel.MUL8_FAST))  # Immediate
        output.append("push af")
        return output

    @classmethod
    def divu8(cls, ins: Quad) -> list[str]:
        """Divides 2 8bit unsigned integers. The result is pushed onto the stack.

        Optimizations:
          * If 2nd op is 1 then
            do nothing

          * If 2nd op is 2 then
            Shift Right Logical
        """
        op1, op2 = tuple(ins[2:])
        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 1:
                output.append("push af")
                return output

            if op2 == 2:
                output.append("srl a")
                output.append("push af")
                return output

            output.append("ld h, %i" % cls.int8(op2))
        else:
            if op2[0] == "_":  # Optimization when 2nd operand is an id
                if is_int(op1) and int(op1) == 0:
                    output = []  # Optimization: Discard previous op if not from the stack
                    output.append("xor a")
                    output.append("push af")
                    return output

                rev = True
                op1, op2 = op2, op1
            else:
                rev = False

            output = cls.get_oper(op1, op2, reversed_=rev)

        output.append(runtime_call(RuntimeLabel.DIVU8_FAST))
        output.append("push af")
        return output

    @classmethod
    def divi8(cls, ins: Quad) -> list[str]:
        """Divides 2 8bit signed integers. The result is pushed onto the stack.

        Optimizations:
          * If 2nd op is 1 then
            do nothing

          * If 2nd op is 2 then
            Shift Right Arithmetic
        """
        op1, op2 = tuple(ins[2:])
        if is_int(op2):
            op2 = int(op2) & 0xFF
            output = cls.get_oper(op1)

            if op2 == 1:
                output.append("push af")
                return output

            if op2 == -1:
                output.append("neg")
                output.append("push af")
                return output

            if op2 == 2:
                output.append("sra a")
                output.append("push af")
                return output

            output.append("ld h, %i" % cls.int8(op2))
        else:
            if op2[0] == "_":  # Optimization when 2nd operand is an id
                if is_int(op1) and int(op1) == 0:
                    output = []  # Optimization: Discard previous op if not from the stack
                    output.append("xor a")
                    output.append("push af")
                    return output

                rev = True
                op1, op2 = op2, op1
            else:
                rev = False

            output = cls.get_oper(op1, op2, reversed_=rev)

        output.append(runtime_call(RuntimeLabel.DIVI8_FAST))
        output.append("push af")
        return output

    @classmethod
    def modu8(cls, ins: Quad) -> list[str]:
        """Reminder of div. 2 8bit unsigned integers. The result is pushed onto the stack.

        Optimizations:
          * If 2nd operands is 1 then
            returns 0

          * If 2nd operand = 2^n => do AND (2^n - 1)

        """
        op1, op2 = tuple(ins[2:])
        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 1:
                if op1[0] == "_":
                    output = []  # Optimization: Discard previous op if not from the stack

                output.append("xor a")
                output.append("push af")
                return output

            if is_2n(op2):
                output.append("and %i" % (op2 - 1))
                output.append("push af")
                return output

            output.append("ld h, %i" % cls.int8(op2))
        else:
            if op2[0] == "_":  # Optimization when 2nd operand is an id
                if is_int(op1) and int(op1) == 0:
                    output = []  # Optimization: Discard previous op if not from the stack
                    output.append("xor a")
                    output.append("push af")
                    return output

                rev = True
                op1, op2 = op2, op1
            else:
                rev = False

            output = cls.get_oper(op1, op2, reversed_=rev)

        output.append(runtime_call(RuntimeLabel.MODU8_FAST))
        output.append("push af")
        return output

    @classmethod
    def modi8(cls, ins: Quad) -> list[str]:
        """Reminder of div. 2 8bit unsigned integers. The result is pushed onto the stack.

        Optimizations:
          * If 2nd operands is 1 then
            returns 0

          * If 2nd operand = 2^n => do AND (2^n - 1)

        """
        op1, op2 = tuple(ins[2:])
        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 1:
                if op1[0] == "_":
                    output = []  # Optimization: Discard previous op if not from the stack

                output.append("xor a")
                output.append("push af")
                return output

            if is_2n(op2):
                output.append("and %i" % (op2 - 1))
                output.append("push af")
                return output

            output.append("ld h, %i" % cls.int8(op2))
        else:
            if op2[0] == "_":  # Optimization when 2nd operand is an id
                if is_int(op1) and int(op1) == 0:
                    output = []  # Optimization: Discard previous op if not from the stack
                    output.append("xor a")
                    output.append("push af")
                    return output

                rev = True
                op1, op2 = op2, op1
            else:
                rev = False

            output = cls.get_oper(op1, op2, reversed_=rev)

        output.append(runtime_call(RuntimeLabel.MODI8_FAST))
        output.append("push af")
        return output

    @classmethod
    def ltu8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
        """
        output = cls.get_oper(ins[2], ins[3])
        output.append("cp h")
        output.append("sbc a, a")
        output.append("push af")

        return output

    @classmethod
    def lti8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
        """
        output = []
        output.extend(cls.get_oper(ins[2], ins[3]))
        output.append(runtime_call(RuntimeLabel.LTI8))
        output.append("push af")

        return output

    @classmethod
    def gtu8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
        """
        output = cls.get_oper(ins[2], ins[3], reversed_=True)
        output.append("cp h")
        output.append("sbc a, a")
        output.append("push af")

        return output

    @classmethod
    def gti8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
        """
        output = cls.get_oper(ins[2], ins[3], reversed_=True)
        output.append(runtime_call(RuntimeLabel.LTI8))
        output.append("push af")

        return output

    @classmethod
    def eq8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit un/signed version
        """
        if is_int(ins[3]):
            output = cls.get_oper(ins[2])
            n = cls.int8(ins[3])
            if n:
                if n == 1:
                    output.append("dec a")
                else:
                    output.append("sub %i" % n)
        else:
            output = cls.get_oper(ins[2], ins[3])
            output.append("sub h")

        output.append("sub 1")  # Sets Carry only if 0
        output.append("sbc a, a")
        output.append("push af")

        return output

    @classmethod
    def leu8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
        """
        output = cls.get_oper(ins[2], ins[3], reversed_=True)
        output.append("sub h")  # Carry if H > A
        output.append("ccf")  # Negates => Carry if H <= A
        output.append("sbc a, a")
        output.append("push af")

        return output

    @classmethod
    def lei8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
        """
        output = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabel.LEI8))
        output.append("push af")

        return output

    @classmethod
    def geu8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
        """
        if is_int(ins[3]):
            output = cls.get_oper(ins[2])
            n = cls.int8(ins[3])
            if n:
                output.append("sub %i" % n)
            else:
                output.append("cp a")
        else:
            output = cls.get_oper(ins[2], ins[3])
            output.append("sub h")

        output.append("ccf")
        output.append("sbc a, a")
        output.append("push af")

        return output

    @classmethod
    def gei8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
        """
        output = cls.get_oper(ins[2], ins[3], reversed_=True)
        output.append(runtime_call(RuntimeLabel.LEI8))
        output.append("push af")

        return output

    @classmethod
    def ne8(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit un/signed version
        """
        if is_int(ins[3]):
            output = cls.get_oper(ins[2])
            n = cls.int8(ins[3])
            if n:
                if n == 1:
                    output.append("dec a")
                else:
                    output.append("sub %i" % cls.int8(ins[3]))
        else:
            output = cls.get_oper(ins[2], ins[3])
            output.append("sub h")

        output.append("push af")

        return output

    @classmethod
    def or8(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if 1st operand OR (logical) 2nd operand (top of the stack),
        pushes 0 if False, not 0 if True.

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)
            if op2 == 0:  # X or False = X
                output.append("push af")
                return output

            # X or True = True
            output.append("ld a, 1")  # True
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2)
        output.append("or h")
        output.append("push af")

        return output

    @classmethod
    def bor8(cls, ins: Quad) -> list[str]:
        """pops top 2 operands out of the stack, and does
        OR (bitwise) with 1st and 2nd operand (top of the stack),
        pushes result.

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)
            if op2 == 0:  # X | 0 = X
                output.append("push af")
                return output

            if op2 == 0xFF:  # X | 0xFF = 0xFF
                output.append("ld a, 0FFh")
                output.append("push af")
                return output

            op1, op2 = tuple(ins[2:])

        output = cls.get_oper(op1, op2)
        output.append("or h")
        output.append("push af")

        return output

    @classmethod
    def and8(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if 1st operand AND (logical) 2nd operand (top of the stack),
        pushes 0 if False, not 0 if True.

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)  # Pops the stack (if applicable)
            if op2 != 0:  # X and True = X
                output.append("push af")
                return output

            # False and X = False
            output.append("xor a")
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2)

        lbl = tmp_label()
        output.append("or a")
        output.append("jr z, %s" % lbl)
        output.append("ld a, h")
        output.append("%s:" % lbl)
        output.append("push af")

        return output

    @classmethod
    def band8(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and does
        1st AND (bitwise) 2nd operand (top of the stack),
        pushes the result.

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)
            if op2 == 0xFF:  # X & 0xFF = X
                output.append("push af")
                return output

            if op2 == 0:  # X and 0 = 0
                output.append("xor a")
                output.append("push af")
                return output

            op1, op2 = tuple(ins[2:])

        output = cls.get_oper(op1, op2)
        output.append("and h")
        output.append("push af")

        return output

    @classmethod
    def xor8(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if 1st operand XOR (logical) 2nd operand (top of the stack),
        pushes 0 if False, 1 if True.

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)  # True or X = not X
            if op2 == 0:  # False xor X = X
                output.append("push af")
                return output

            output.append("sub 1")
            output.append("sbc a, a")
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2)
        output.append(runtime_call(RuntimeLabel.XOR8))
        output.append("push af")

        return output

    @classmethod
    def bxor8(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and does
        1st operand XOR (bitwise) 2nd operand (top of the stack),
        pushes the result

        8 bit un/signed version
        """
        op1, op2 = tuple(ins[2:])
        if _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)

            output = cls.get_oper(op1)
            if op2 == 0:  # 0 xor X = X
                output.append("push af")
                return output

            if op2 == 0xFF:  # X xor 0xFF = ~X
                output.append("cpl")
                output.append("push af")
                return output

            op1, op2 = tuple(ins[2:])

        output = cls.get_oper(op1, op2)
        output.append("xor h")
        output.append("push af")

        return output

    @classmethod
    def not8(cls, ins: Quad) -> list[str]:
        """Negates (Logical NOT) top of the stack (8 bits in AF)"""
        output = cls.get_oper(ins[2])
        output.append("sub 1")  # Gives carry only if A = 0
        output.append("sbc a, a")  # Gives FF only if Carry else 0
        output.append("push af")

        return output

    @classmethod
    def bnot8(cls, ins: Quad) -> list[str]:
        """Negates (BITWISE NOT) top of the stack (8 bits in AF)"""
        output = cls.get_oper(ins[2])
        output.append("cpl")  # Gives carry only if A = 0
        output.append("push af")

        return output

    @classmethod
    def neg8(cls, ins: Quad) -> list[str]:
        """Negates top of the stack (8 bits in AF)"""
        output = cls.get_oper(ins[2])
        output.append("neg")
        output.append("push af")

        return output

    @classmethod
    def abs8(cls, ins: Quad) -> list[str]:
        """Absolute value of top of the stack (8 bits in AF)"""
        output = cls.get_oper(ins[2])
        output.append(runtime_call(RuntimeLabel.ABS8))
        output.append("push af")
        return output

    @classmethod
    def shru8(cls, ins: Quad) -> list[str]:
        """Shift 8bit unsigned integer to the right. The result is pushed onto the stack.

        Optimizations:
          * If 1nd or 2nd op is 0 then
            do nothing

          * If 2nd op is < 4 then
            unroll loop
        """
        op1, op2 = tuple(ins[2:])

        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 0:
                output.append("push af")
                return output

            if op2 < 4:
                output.extend(["srl a"] * op2)
                output.append("push af")
                return output

            label = tmp_label()
            output.append("ld b, %i" % cls.int8(op2))
            output.append("%s:" % label)
            output.append("srl a")
            output.append("djnz %s" % label)
            output.append("push af")
            return output

        if is_int(op1) and int(op1) == 0:
            output = cls.get_oper(op2)
            output.append("xor a")
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2, reversed_=True)
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("ld b, a")
        output.append("ld a, h")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append("srl a")
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push af")
        return output

    @classmethod
    def shri8(cls, ins: Quad) -> list[str]:
        """Shift 8bit signed integer to the right. The result is pushed onto the stack.

        Optimizations:
          * If 1nd or 2nd op is 0 then
            do nothing

          * If 2nd op is < 4 then
            unroll loop
        """
        op1, op2 = tuple(ins[2:])

        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 0:
                output.append("push af")
                return output

            if op2 < 4:
                output.extend(["sra a"] * op2)
                output.append("push af")
                return output

            label = tmp_label()
            output.append("ld b, %i" % cls.int8(op2))
            output.append("%s:" % label)
            output.append("sra a")
            output.append("djnz %s" % label)
            output.append("push af")
            return output

        if is_int(op1) and int(op1) == 0:
            output = cls.get_oper(op2)
            output.append("xor a")
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2, reversed_=True)
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("ld b, a")
        output.append("ld a, h")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append("sra a")
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push af")
        return output

    @classmethod
    def shl8(cls, ins: Quad) -> list[str]:
        """Shift 8bit (un)signed integer to the left. The result is pushed onto the stack.

        Optimizations:
          * If 1nd or 2nd op is 0 then
            do nothing

          * If 2nd op is < 4 then
            unroll loop
        """
        op1, op2 = tuple(ins[2:])
        if is_int(op2):
            op2 = cls.int8(op2)

            output = cls.get_oper(op1)
            if op2 == 0:
                output.append("push af")
                return output

            if op2 < 6:
                output.extend(["add a, a"] * op2)
                output.append("push af")
                return output

            label = tmp_label()
            output.append("ld b, %i" % cls.int8(op2))
            output.append("%s:" % label)
            output.append("add a, a")
            output.append("djnz %s" % label)
            output.append("push af")
            return output

        if is_int(op1) and int(op1) == 0:
            output = cls.get_oper(op2)
            output.append("xor a")
            output.append("push af")
            return output

        output = cls.get_oper(op1, op2, reversed_=True)
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("ld b, a")
        output.append("ld a, h")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append("add a, a")
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push af")
        return output

    @classmethod
    def load8(cls, ins: Quad) -> list[str]:
        """Loads an 8 bit value from a memory address
        If 2nd arg. start with '*', it is always treated as
        an indirect value.
        """
        output = cls.get_oper(ins[2])
        output.append("push af")
        return output

    @classmethod
    def store8(cls, ins: Quad) -> list[str]:
        """Stores 2nd operand content into address of 1st operand.
        store8 a, x =>  a = x
        Use '*' for indirect store on 1st operand.
        """
        output = cls.get_oper(ins[2])

        op = ins[1]

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"
        if immediate:
            op = op[1:]

        if is_int(op) or op[0] in "_.":
            if is_int(op):
                op = str(int(op) & 0xFFFF)

            if immediate:
                if indirect:
                    output.append("ld (%s), a" % op)
                else:  # ???
                    output.append("ld (%s), a" % op)
            elif indirect:
                output.append("ld hl, (%s)" % op)
                output.append("ld (hl), a")
            else:
                output.append("ld (%s), a" % op)
        else:
            if immediate:
                if indirect:  # A label not starting with _
                    output.append("ld hl, (%s)" % op)
                    output.append("ld (hl), a")
                else:
                    output.append("ld (%s), a" % op)
                return output
            output.append("pop hl")

            if indirect:
                output.append("ld e, (hl)")
                output.append("inc hl")
                output.append("ld d, (hl)")
                output.append("ld (de), a")
            else:
                output.append("ld (hl), a")

        return output

    @classmethod
    def jzero8(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (8bit) is 0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) == 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("or a")
        output.append("jp z, %s" % str(ins[2]))
        return output

    @classmethod
    def jnzero8(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (8bit) is != 0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) != 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("or a")
        output.append("jp nz, %s" % str(ins[2]))
        return output

    @classmethod
    def jgezerou8(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (8bit) is >= 0 to arg(1)
        Always TRUE for unsigned
        """
        output = []
        value = ins[1]
        if not is_int(value):
            output = cls.get_oper(value)

        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def jgezeroi8(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (8bit) is >= 0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) >= 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("add a, a")  # Puts sign into carry
        output.append("jp nc, %s" % str(ins[2]))
        return output

    @classmethod
    def ret8(cls, ins: Quad) -> list[str]:
        """Returns from a procedure / function an 8bits value"""
        output = cls.get_oper(ins[1])
        output.append("#pragma opt require a")
        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def param8(cls, ins: Quad) -> list[str]:
        """Pushes 8bit param into the stack"""
        output = cls.get_oper(ins[1])
        output.append("push af")
        return output

    @classmethod
    def fparam8(cls, ins: Quad) -> list[str]:
        """Passes a byte as a __FASTCALL__ parameter.
        This is done by popping out of the stack for a
        value, or by loading it from memory (indirect)
        or directly (immediate)
        """
        return cls.get_oper(ins[1])
