# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 32 bit boolean, arithmetic and
# comparison intermediate-code translation
# --------------------------------------------------------------

from src.api.tmp_labels import tmp_label
from src.arch.z80.backend._8bit import Bits8
from src.arch.z80.backend.common import _int_ops, is_int, runtime_call
from src.arch.z80.backend.quad import Quad
from src.arch.z80.backend.runtime import Labels as RuntimeLabel

# -----------------------------------------------------
# 32 bits operands
# -----------------------------------------------------

__all__ = ("Bits32",)


class Bits32:
    """Implementation of 32bit (u32, i32) operations."""

    @classmethod
    def int32(cls, op) -> tuple[int, int]:
        """Returns a 32 bit operand converted to 32 bits unsigned int.
        Negative numbers are returned in 2 complement.

        The result is returned in a tuple (DE, HL) => High16, Low16
        """
        result = int(op) & 0xFFFFFFFF
        return result >> 16, result & 0xFFFF

    @classmethod
    def get_oper(
        cls,
        op1: str,
        op2: str | None = None,
        *,
        reversed: bool = False,
        preserveHL: bool = False,
    ) -> list[str]:
        """Returns pop sequence for 32 bits operands
        1st operand in HLDE, 2nd operand remains in the stack

        Now it does support operands inversion calling __SWAP32.

        However, if 1st operand is integer (immediate) or indirect, the stack
        will be rearranged, so it contains a 32 bit pushed parameter value for the
        subroutine to be called.

        If preserveHL is True, then BC will be used instead of HL for lower part
        for the 1st operand.
        """
        output: list[str] = []
        op = op2 if op2 is not None else op1
        int1 = False  # whether op1 (2nd operand) is integer

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"
        if immediate:
            op = op[1:]

        hl = "hl" if not preserveHL else "bc"

        if is_int(op):
            int1 = True
            if indirect:
                if immediate:
                    output.append(f"ld hl, {op}")
                else:
                    output.append(f"ld hl, ({op})")

                output.append(runtime_call(RuntimeLabel.ILOAD32))

                if preserveHL:
                    output.append("ld b, h")
                    output.append("ld c, l")
            else:
                DE, HL = cls.int32(op)
                output.append("ld de, %i" % DE)
                output.append("ld %s, %i" % (hl, HL))
        else:
            if op[0] == "_":
                if immediate:
                    output.append("ld %s, %s" % (hl, op))
                else:
                    output.append("ld %s, (%s)" % (hl, op))
            else:
                if immediate:
                    output.append("ld %s, (%s) & 0xFFFF" % (hl, op))
                else:
                    output.append("pop %s" % hl)

            if indirect:
                output.append(runtime_call(RuntimeLabel.ILOAD32))

                if preserveHL:
                    output.append("ld b, h")
                    output.append("ld c, l")
            else:
                if op[0] == "_":
                    output.append("ld de, (%s + 2)" % op)
                else:
                    if immediate:
                        output.append("ld de, (%s) >> 16" % op)
                    else:
                        output.append("pop de")

        if op2 is not None:
            op = op1

            indirect = op[0] == "*"
            if indirect:
                op = op[1:]

            immediate = op[0] == "#"
            if immediate:
                op = op[1:]

            if is_int(op):
                op = int(op)

                if indirect:
                    output.append("exx")
                    if immediate:
                        output.append("ld hl, %i" % (op & 0xFFFF))
                    else:
                        output.append("ld hl, (%i)" % (op & 0xFFFF))

                    output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used
                    output.append("push de")
                    output.append("push hl")
                    output.append("exx")
                else:
                    DE, HL = cls.int32(op)
                    output.append("ld bc, %i" % DE)
                    output.append("push bc")
                    output.append("ld bc, %i" % HL)
                    output.append("push bc")
            else:
                if indirect:
                    output.append("exx")  # uses alternate set to put it on the stack
                    if op[0] == "_":
                        if immediate:
                            output.append("ld hl, %s" % op)
                        else:
                            output.append("ld hl, (%s)" % op)
                    else:
                        output.append("pop hl")  # Pointers are only 16 bits ***

                    output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used
                    output.append("push de")
                    output.append("push hl")
                    output.append("exx")
                elif immediate:
                    output.append("ld bc, (%s) >> 16" % op)
                    output.append("push bc")
                    output.append("ld bc, (%s) & 0xFFFF" % op)
                    output.append("push bc")
                elif op[0] == "_":  # an address
                    if int1 or op1[0] == "_":  # If previous op was integer, we can use hl in advance
                        tmp = output
                        output = []
                        output.append("ld hl, (%s + 2)" % op)
                        output.append("push hl")
                        output.append("ld hl, (%s)" % op)
                        output.append("push hl")
                        output.extend(tmp)
                    else:
                        output.append("ld bc, (%s + 2)" % op)
                        output.append("push bc")
                        output.append("ld bc, (%s)" % op)
                        output.append("push bc")
                else:
                    pass  # 2nd operand remains in the stack

        if op2 is not None and reversed:
            output.append(runtime_call(RuntimeLabel.SWAP32))

        return output

    @classmethod
    def bool_binary(cls, ins: Quad, label: str, *, commutative: bool) -> list[str]:
        """Outputs the assembler sequence for a binary (2 args) function that outputs
        a boolean (byte) value.

        :param ins: The Quad intermediate code
        :param label: The Label of the ASM routine that computes the result.
        :param commutative: If true, the operands may be reversed in the stack for efficiency.
        """
        op1, op2 = ins.args[1:]
        rev = commutative and op1[0] != "t" and not is_int(op1) and op2[0] == "t"

        if commutative and _int_ops(op1, op2) is not None:
            op1, op2 = _int_ops(op1, op2)  # Op2 is always integer
            op2 = str(op2)

        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(label))
        output.append("push af")
        return output

    @classmethod
    def unary(cls, ins: Quad, label: str) -> list[str]:
        output = cls.get_oper(ins[2])
        output.append(runtime_call(label))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def to_bool(
        cls,
    ) -> list[str]:
        return [
            "sbc a, a",
            "neg",
            "push af",
        ]  # 0 if not Carry, -1 if Carry  # 0 if not Carry (false), 1 if Carry (true),

    # -----------------------------------------------------
    #               Arithmetic operations
    # -----------------------------------------------------

    @classmethod
    def add32(cls, ins: Quad) -> list[str]:
        """Pops last 2 bytes from the stack and adds them.
        Then push the result onto the stack.

        Optimizations:
          * If any of the operands is ZERO,
            then do NOTHING: A + 0 = 0 + A = A
        """
        op1, op2 = ins.args[1:]

        if _int_ops(op1, op2) is not None:
            o1, o2 = _int_ops(op1, op2)

            if int(o2) == 0:  # A + 0 = 0 + A = A => Do Nothing
                output = cls.get_oper(o1)
                output.append("push de")
                output.append("push hl")
                return output

        if op1[0] == "_" and op2[0] != "_":
            op1, op2 = op2, op1  # swap them

        if op2[0] == "_":
            output = cls.get_oper(op1)
            output.append("ld bc, (%s)" % op2)
            output.append("add hl, bc")
            output.append("ex de, hl")
            output.append("ld bc, (%s + 2)" % op2)
            output.append("adc hl, bc")
            output.append("push hl")
            output.append("push de")
            return output

        output = cls.get_oper(op1, op2)
        output.append("pop bc")
        output.append("add hl, bc")
        output.append("ex de, hl")
        output.append("pop bc")
        output.append("adc hl, bc")
        output.append("push hl")  # High and low parts are reversed
        output.append("push de")

        return output

    @classmethod
    def sub32(cls, ins: Quad) -> list[str]:
        """Pops last 2 dwords from the stack and subtract them.
        Then push the result onto the stack.
        NOTE: The operation is TOP[0] = TOP[-1] - TOP[0]

        If TOP[0] is 0, nothing is done
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            if int(op2) == 0:  # A - 0 = A => Do Nothing
                output = cls.get_oper(op1)
                output.append("push de")
                output.append("push hl")
                return output

        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"

        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.SUB32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def mul32(cls, ins: Quad) -> list[str]:
        """Multiplies two last 32bit values on top of the stack and
        and returns the value on top of the stack

        Optimizations done:

            * If any operand is 1, do nothing
            * If any operand is 0, push 0
        """
        op1, op2 = ins.args[1:]

        if _int_ops(op1, op2):
            op1, op2 = _int_ops(op1, op2)
            output = cls.get_oper(op1)

            if op2 == 1:
                output.append("push de")
                output.append("push hl")
                return output  # A * 1 = Nothing

            if op2 == 0:
                output.append("ld hl, 0")
                output.append("push hl")
                output.append("push hl")
                return output

            op2 = str(op2)  # convert it back to str

        output = cls.get_oper(op1, op2)
        output.append(runtime_call(RuntimeLabel.MUL32))  # Immediate
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def divu32(cls, ins: Quad) -> list[str]:
        """Divides 2 32bit unsigned integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 1, do nothing
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            if int(op2) == 1:
                output = cls.get_oper(op1)
                output.append("push de")
                output.append("push hl")
                return output

        rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.DIVU32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def divi32(cls, ins: Quad) -> list[str]:
        """Divides 2 32bit signed integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 1, do nothing
         * If 2nd operand is -1, do NEG32
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            if int(op2) == 1:
                output = cls.get_oper(op1)
                output.append("push de")
                output.append("push hl")
                return output

            if int(op2) == -1:
                return cls.neg32(ins)

        rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.DIVI32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def modu32(cls, ins: Quad) -> list[str]:
        """Reminder of div. 2 32bit unsigned integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd op is 1. Returns 0
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            if int(op2) == 1:
                output = cls.get_oper(op1)
                output.append("ld hl, 0")
                output.append("push hl")
                output.append("push hl")
                return output

        rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.MODU32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def modi32(cls, ins: Quad) -> list[str]:
        """Reminder of div. 2 32bit signed integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd op is 1. Returns 0
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            if int(op2) == 1:
                output = cls.get_oper(op1)
                output.append("ld hl, 0")
                output.append("push hl")
                output.append("push hl")
                return output

        rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.MODI32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def ltu32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit unsigned version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.SUB32))
        output.append("sbc a, a")
        output.append("push af")
        return output

    @classmethod
    def lti32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit signed version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.LTI32))  # Checks A <= B ?
        output.append("push af")
        return output

    @classmethod
    def gtu32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit unsigned version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append("pop bc")
        output.append("or a")
        output.append("sbc hl, bc")
        output.append("ex de, hl")
        output.append("pop de")
        output.append("sbc hl, de")
        output.append("sbc a, a")
        output.append("push af")
        return output

    @classmethod
    def gti32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit signed version
        """
        # TODO: Refact this as a call to _lei32() + pop af + ...
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.LEI32))  # Checks A <= B ?
        output.append("sub 1")  # Carry if A = 0 (False)
        output.append("sbc a, a")  # Negates => A > B ?
        output.append("push af")
        return output

    @classmethod
    def leu32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit unsigned version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append("pop bc")
        output.append("or a")
        output.append("sbc hl, bc")
        output.append("ex de, hl")
        output.append("pop de")
        output.append("sbc hl, de")  # Carry if A > B
        output.append("ccf")  # Negates result => Carry if A <= B
        output.append("sbc a, a")
        output.append("push af")
        return output

    @classmethod
    def lei32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit signed version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.LEI32))  # Checks A <= B ?
        output.append("push af")
        return output

    @classmethod
    def geu32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit unsigned version
        """
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.SUB32))  # Carry if A < B
        output.append("ccf")  # Negates result => Carry if A >= B
        output.append("sbc a, a")
        output.append("push af")
        return output

    @classmethod
    def gei32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit signed version
        """
        # TODO: Refact this as negated Boolean
        op1, op2 = ins.args[1:]
        rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
        output = cls.get_oper(op1, op2, reversed=rev)
        output.append(runtime_call(RuntimeLabel.LTI32))  # A = (a < b)
        output.append("sub 1")  # Carry if !(a < b)
        output.append("sbc a, a")  # A = !(a < b) = (a >= b)
        output.append("push af")
        return output

    @classmethod
    def eq32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit un/signed version
        """
        return cls.bool_binary(ins, RuntimeLabel.EQ32, commutative=False)

    @classmethod
    def ne32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit un/signed version
        """
        output = cls.eq32(ins)[:-1]  # Compare 32 bits, but do not push result
        output.append("sub 1")  # Carry if A = 0 (False)
        output.append("sbc a, a")  # Negates => !(A == B)
        output.append("push af")
        return output

    @classmethod
    def or32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand OR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit un/signed version
        """
        return cls.bool_binary(ins, RuntimeLabel.OR32, commutative=False)

    @classmethod
    def bor32(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if the 1st operand OR (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
        """
        op1, op2 = ins.args[1:]
        output = cls.get_oper(op1, op2)
        output.append(runtime_call(RuntimeLabel.BOR32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def xor32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit un/signed version
        """
        return cls.bool_binary(ins, RuntimeLabel.XOR32, commutative=False)

    @classmethod
    def bxor32(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
        """
        op1, op2 = ins.args[1:]
        output = cls.get_oper(op1, op2)
        output.append(runtime_call(RuntimeLabel.BXOR32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def and32(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand AND (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        32 bit un/signed version
        """
        op1, op2 = ins.args[1:]

        if _int_ops(op1, op2):
            op1, op2 = _int_ops(op1, op2)

            if op2 == 0:  # X and False = False  # TODO: Move this to the optimizer
                if str(op1)[0] == "t":  # a temporary term (stack)
                    output = cls.get_oper(op1)  # Remove op1 from the stack
                else:
                    output = []
                output.append("xor a")
                output.append("push af")
                return output

                # For X and TRUE = X we do nothing as we have to convert it to boolean
                # which is a rather expensive instruction

        return cls.bool_binary(ins, RuntimeLabel.AND32, commutative=True)

    @classmethod
    def band32(cls, ins: Quad) -> list[str]:
        """Pops top 2 operands out of the stack, and checks
        if the 1st operand AND (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
        """
        op1, op2 = ins.args[1:]
        output = cls.get_oper(op1, op2)
        output.append(runtime_call(RuntimeLabel.BAND32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def not32(cls, ins: Quad) -> list[str]:
        """Negates top (Logical NOT) of the stack (32 bits in DEHL)"""
        output = cls.get_oper(ins[2])
        output.append(runtime_call(RuntimeLabel.NOT32))
        output.append("push af")
        return output

    @classmethod
    def bnot32(cls, ins: Quad) -> list[str]:
        """Negates top (Bitwise NOT) of the stack (32 bits in DEHL)"""
        output = cls.get_oper(ins[2])
        output.append(runtime_call(RuntimeLabel.BNOT32))
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def neg32(cls, ins: Quad) -> list[str]:
        """Negates top of the stack (32 bits in DEHL)"""
        return cls.unary(ins, RuntimeLabel.NEG32)

    @classmethod
    def abs32(cls, ins: Quad) -> list[str]:
        """Absolute value of top of the stack (32 bits in DEHL)"""
        return cls.unary(ins, RuntimeLabel.ABS32)

    @classmethod
    def shru32(cls, ins: Quad) -> list[str]:
        """Logical Right shift 32bit unsigned integers.
        The result is pushed onto the stack.

            Optimizations:

             * If 2nd operand is 0, do nothing
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            output = cls.get_oper(op1)

            if int(op2) == 0:
                output.append("push de")
                output.append("push hl")
                return output

            if int(op2) > 1:
                label = tmp_label()
                output.append("ld b, %s" % op2)
                output.append("%s:" % label)
                output.append(runtime_call(RuntimeLabel.SHRL32))
                output.append("djnz %s" % label)
            else:
                output.append(runtime_call(RuntimeLabel.SHRL32))

            output.append("push de")
            output.append("push hl")
            return output

        output = Bits8.get_oper(op2)
        output.append("ld b, a")
        output.extend(cls.get_oper(op1))
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append(runtime_call(RuntimeLabel.SHRL32))
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def shri32(cls, ins: Quad) -> list[str]:
        """Logical Right shift 32bit unsigned integers.
        The result is pushed onto the stack.

            Optimizations:

             * If 2nd operand is 0, do nothing
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            output = cls.get_oper(op1)

            if int(op2) == 0:
                output.append("push de")
                output.append("push hl")
                return output

            if int(op2) > 1:
                label = tmp_label()
                output.append("ld b, %s" % op2)
                output.append("%s:" % label)
                output.append(runtime_call(RuntimeLabel.SHRA32))
                output.append("djnz %s" % label)
            else:
                output.append(runtime_call(RuntimeLabel.SHRA32))

            output.append("push de")
            output.append("push hl")
            return output

        output = Bits8.get_oper(op2)
        output.append("ld b, a")
        output.extend(cls.get_oper(op1))
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append(runtime_call(RuntimeLabel.SHRA32))
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def shl32(cls, ins: Quad) -> list[str]:
        """Logical Left shift 32bit unsigned integers.
        The result is pushed onto the stack.

            Optimizations:

             * If 2nd operand is 0, do nothing
        """
        op1, op2 = ins.args[1:]

        if is_int(op2):
            output = cls.get_oper(op1)

            if int(op2) == 0:
                output.append("push de")
                output.append("push hl")
                return output

            if int(op2) > 1:
                label = tmp_label()
                output.append("ld b, %s" % op2)
                output.append("%s:" % label)
                output.append(runtime_call(RuntimeLabel.SHL32))
                output.append("djnz %s" % label)
            else:
                output.append(runtime_call(RuntimeLabel.SHL32))

            output.append("push de")
            output.append("push hl")
            return output

        output = Bits8.get_oper(op2)
        output.append("ld b, a")
        output.extend(cls.get_oper(op1))
        label = tmp_label()
        label2 = tmp_label()
        output.append("or a")
        output.append("jr z, %s" % label2)
        output.append("%s:" % label)
        output.append(runtime_call(RuntimeLabel.SHL32))
        output.append("djnz %s" % label)
        output.append("%s:" % label2)
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def load32(cls, ins: Quad) -> list[str]:
        """Load a 32 bit value from a memory address
        If 2nd arg. start with '*', it is always treated as
        an indirect value.
        """
        output = cls.get_oper(ins[2])
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def store32(cls, ins: Quad) -> list[str]:
        """Stores 2nd operand content into address of 1st operand.
        store16 a, x =>  *(&a) = x
        """
        op = ins[1]

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"  # Might make no sense here?
        if immediate:
            op = op[1:]

        if is_int(op) or op[0] in "_." or immediate:
            output = cls.get_oper(ins[2], preserveHL=indirect)

            if is_int(op):
                op = str(int(op) & 0xFFFF)

            if indirect:
                output.append("ld hl, (%s)" % op)
                output.append(runtime_call(RuntimeLabel.STORE32))  # TODO: is this ever used?
                return output

            output.append("ld (%s), hl" % op)
            output.append("ld (%s + 2), de" % op)

            return output

        output = cls.get_oper(ins[2], preserveHL=True)
        output.append("pop hl")

        if indirect:
            output.append(runtime_call(RuntimeLabel.ISTORE32))  # TODO: is this ever used?

            return output

        output.append(runtime_call(RuntimeLabel.STORE32))
        return output

    @classmethod
    def jzero32(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (32bit) is 0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) == 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("ld a, h")
        output.append("or l")
        output.append("or e")
        output.append("or d")
        output.append("jp z, %s" % str(ins[2]))
        return output

    @classmethod
    def jgezerou32(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (23bit) is >= 0 to arg(1)
        Always TRUE for unsigned
        """
        output = []
        value = ins[1]
        if not is_int(value):
            output = cls.get_oper(value)

        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def jgezeroi32(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (32bit) is >= 0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) >= 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("ld a, d")
        output.append("add a, a")  # Puts sign into carry
        output.append("jp nc, %s" % str(ins[2]))
        return output

    @classmethod
    def ret32(cls, ins: Quad) -> list[str]:
        """Returns from a procedure / function a 32bits value (even Fixed point)"""
        output = cls.get_oper(ins[1])
        output.append("#pragma opt require hl,de")
        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def param32(cls, ins: Quad) -> list[str]:
        """Pushes 32bit param into the stack"""
        output = cls.get_oper(ins[1])
        output.append("push de")
        output.append("push hl")
        return output

    @classmethod
    def fparam32(cls, ins: Quad) -> list[str]:
        """Passes a dword as a __FASTCALL__ parameter.
        This is done by popping out of the stack for a
        value, or by loading it from memory (indirect)
        or directly (immediate)
        """
        return cls.get_oper(ins[1])

    @classmethod
    def jnzero32(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack (32bit) is !=0 to arg(1)"""
        value = ins[1]
        if is_int(value):
            if int(value) != 0:
                return ["jp %s" % str(ins[2])]  # Always true
            return []

        output = cls.get_oper(value)
        output.append("ld a, h")
        output.append("or l")
        output.append("or e")
        output.append("or d")
        output.append("jp nz, %s" % str(ins[2]))
        return output
