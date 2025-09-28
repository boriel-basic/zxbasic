# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .common import runtime_call
from .exception import InvalidICError as InvalidIC
from .quad import Quad
from .runtime import Labels as RuntimeLabel
from .runtime import Labels as RuntimeLabels


class String:
    @classmethod
    def get_oper(
        cls, op1, op2=None, *, reversed: bool = False, no_exaf: bool = False
    ) -> tuple[bool, list[str]] | tuple[bool, bool, list[str]]:
        """Returns pop sequence for 16 bits operands
        1st operand in HL, 2nd operand in DE

        You can swap operators extraction order
        by setting reversed to True.

        If no_exaf = True => No bits flags in A' will be used.
                            This saves two bytes.
        """
        output = []

        if op2 is not None and reversed:
            op1, op2 = op2, op1

        tmp2 = False
        if op2 is not None:
            val = op2
            if val[0] == "*":
                indirect = True
                val = val[1:]
            else:
                indirect = False

            if val[0] == "_":  # Direct
                output.append("ld de, (%s)" % val)
            elif val[0] == "#":  # Direct
                output.append("ld de, %s" % val[1:])
            elif val[0] == "$":  # Direct in the stack
                output.append("pop de")
            else:
                output.append("pop de")
                tmp2 = True

            if indirect:
                output.append(runtime_call(RuntimeLabels.LOAD_DE_DE))  # TODO: Is this ever used??

        if reversed:
            tmp = output
            output = []

        val = op1
        tmp1 = False
        if val[0] == "*":
            indirect = True
            val = val[1:]
        else:
            indirect = False

        if val[0] == "_":  # Direct
            output.append("ld hl, (%s)" % val)
        elif val[0] == "#":  # Immediate
            output.append("ld hl, %s" % val[1:])
        elif val[0] == "$":  # Direct in the stack
            output.append("pop hl")
        else:
            output.append("pop hl")
            tmp1 = True

        if indirect:
            output.append("ld c, (hl)")
            output.append("inc hl")
            output.append("ld h, (hl)")
            output.append("ld l, c")

        if reversed:
            output.extend(tmp)

        if not no_exaf:
            if tmp1 and tmp2:
                output.append("ld a, 3")  # Marks both strings to be freed
            elif tmp1:
                output.append("ld a, 1")  # Marks str1 to be freed
            elif tmp2:
                output.append("ld a, 2")  # Marks str2 to be freed
            else:
                output.append("xor a")  # Marks no string to be freed

        if op2 is not None:
            return tmp1, tmp2, output

        return tmp1, output

    @classmethod
    def free_sequence(cls, tmp1, tmp2=False) -> list[str]:
        """Outputs a FREEMEM sequence for 1 or 2 ops"""
        if not tmp1 and not tmp2:
            return []

        output = []
        if tmp1 and tmp2:
            output.append("pop de")
            output.append("ex (sp), hl")
            output.append("push de")
            output.append(runtime_call(RuntimeLabels.MEM_FREE))
            output.append("pop hl")
            output.append(runtime_call(RuntimeLabels.MEM_FREE))
        else:
            output.append("ex (sp), hl")
            output.append(runtime_call(RuntimeLabels.MEM_FREE))

        output.append("pop hl")
        return output

    @classmethod
    def addstr(cls, ins: Quad) -> list[str]:
        """Adds 2 string values. The result is pushed onto the stack.
        Note: This instruction does admit direct strings (as labels).
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3], no_exaf=True)

        if tmp1:
            output.append("push hl")

        if tmp2:
            output.append("push de")

        output.append(runtime_call(RuntimeLabels.ADDSTR))
        output.extend(cls.free_sequence(tmp1, tmp2))
        output.append("push hl")
        return output

    @classmethod
    def ltstr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ < b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STRLT))
        output.append("push af")
        return output

    @classmethod
    def gtstr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ > b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STRGT))
        output.append("push af")
        return output

    @classmethod
    def lestr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ <= b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STRLE))
        output.append("push af")
        return output

    @classmethod
    def gestr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ >= b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STRGE))
        output.append("push af")
        return output

    @classmethod
    def eqstr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ == b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STREQ))
        output.append("push af")
        return output

    @classmethod
    def nestr(cls, ins: Quad) -> list[str]:
        """Compares & pops top 2 strings out of the stack.
        Temporal values are freed from memory. (a$ != b$)
        """
        (tmp1, tmp2, output) = cls.get_oper(ins[2], ins[3])
        output.append(runtime_call(RuntimeLabels.STRNE))
        output.append("push af")
        return output

    @classmethod
    def lenstr(cls, ins: Quad) -> list[str]:
        """Returns string length"""
        (tmp1, output) = cls.get_oper(ins[2], no_exaf=True)
        if tmp1:
            output.append("push hl")

        output.append(runtime_call(RuntimeLabels.STRLEN))
        output.extend(cls.free_sequence(tmp1))
        output.append("push hl")
        return output

    @classmethod
    def loadstr(cls, ins: Quad) -> list[str]:
        """Loads a string value from a memory address."""
        temporal, output = cls.get_oper(ins[2], no_exaf=True)

        if not temporal:
            output.append(runtime_call(RuntimeLabel.LOADSTR))

        output.append("push hl")
        return output

    @classmethod
    def storestr(cls, ins: Quad) -> list[str]:
        """Stores a string value into a memory address.
        It copies content of 2nd operand (string), into 1st, reallocating
        dynamic memory for the 1st str. These instruction DOES ALLOW
        immediate strings for the 2nd parameter, starting with '#'.

        Must prepend '#' (immediate sigil) to 1st operand, as we need
        the & address of the destination.
        """
        op1 = ins[1]
        indirect = op1[0] == "*"
        if indirect:
            op1 = op1[1:]

        immediate = op1[0] == "#"
        if immediate and not indirect:
            raise InvalidIC("storestr does not allow immediate destination", ins)

        if not indirect:
            op1 = "#" + op1

        tmp1, tmp2, output = cls.get_oper(op1, ins[2], no_exaf=True)

        if not tmp2:
            output.append(runtime_call(RuntimeLabel.STORE_STR))
        else:
            output.append(runtime_call(RuntimeLabel.STORE_STR2))

        return output

    @classmethod
    def jzerostr(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack contains a NULL pointer
        or its len is Zero
        """
        # TODO: Check if this is ever used?
        output = []
        disposable = False  # True if string must be freed from memory

        if ins[1][0] == "_":  # Variable?
            output.append("ld hl, (%s)" % ins[1][0])
        else:
            output.append("pop hl")
            output.append("push hl")  # Saves it for later
            disposable = True

        output.append(runtime_call(RuntimeLabel.STRLEN))

        if disposable:
            output.append("ex (sp), hl")
            output.append(runtime_call(RuntimeLabel.MEM_FREE))
            output.append("pop hl")

        output.append("ld a, h")
        output.append("or l")
        output.append("jp z, %s" % str(ins[2]))
        return output

    @classmethod
    def jnzerostr(cls, ins: Quad) -> list[str]:
        """Jumps if top of the stack contains a string with
        at less 1 char
        """
        # TODO: Check if this is ever used?
        output = []
        disposable = False  # True if string must be freed from memory

        if ins[1][0] == "_":  # Variable?
            output.append("ld hl, (%s)" % ins[1][0])
        else:
            output.append("pop hl")
            output.append("push hl")  # Saves it for later
            disposable = True

        output.append(runtime_call(RuntimeLabel.STRLEN))

        if disposable:
            output.append("ex (sp), hl")
            output.append(runtime_call(RuntimeLabel.MEM_FREE))
            output.append("pop hl")

        output.append("ld a, h")
        output.append("or l")
        output.append("jp nz, %s" % str(ins[2]))
        return output

    @classmethod
    def retstr(cls, ins: Quad) -> list[str]:
        """Returns from a procedure / function a string pointer (16bits) value"""
        tmp, output = cls.get_oper(ins[1], no_exaf=True)

        if not tmp:
            output.append(runtime_call(RuntimeLabel.LOADSTR))

        output.append("#pragma opt require hl")
        output.append("jp %s" % str(ins[2]))
        return output

    @classmethod
    def paramstr(cls, ins: Quad) -> list[str]:
        """Pushes an 16 bit unsigned value, which points
        to a string. For indirect values, it will push
        the pointer to the pointer :-)
        """
        (tmp, output) = cls.get_oper(ins[1])
        output.pop()  # Remove a register flag (useless here)
        tmp = ins[1][0] in ("#", "_")  # Determine if the string must be duplicated

        if tmp:
            output.append(runtime_call(RuntimeLabel.LOADSTR))  # Must be duplicated

        output.append("push hl")
        return output

    @classmethod
    def fparamstr(cls, ins: Quad) -> list[str]:
        """Passes a string ptr as a __FASTCALL__ parameter.
        This is done by popping out of the stack for a
        value, or by loading it from memory (indirect)
        or directly (immediate) --prefixed with '#'--
        """
        (tmp1, output) = cls.get_oper(ins[1])

        return output
