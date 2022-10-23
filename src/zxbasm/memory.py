from bisect import bisect_left, bisect_right
from collections import defaultdict
from typing import Dict, List, Optional, Tuple

from src.api import global_ as gl
from src.api.debug import __DEBUG__
from src.api.errmsg import error, warning
from src.zxbasm import global_ as asm_gl
from src.zxbasm.asm import Asm
from src.zxbasm.global_ import DOT
from src.zxbasm.label import Label


class Memory:
    """A class to describe memory"""

    MAX_MEM = 65535  # Max memory limit
    _tmp_labels: Dict[Tuple[str, int], Dict[str, Label]]
    _tmp_labels_lines: Dict[str, List[int]]
    _tmp_pending_labels: Dict[str, List[Label]]

    def __init__(self, org: int = 0):
        """Initializes the origin of code.
        0 by default"""
        self.index = org  # ORG address (can be changed on the fly)
        self.memory_bytes: Dict[int, int] = {}  # An array (associative) containing memory bytes
        self.local_labels: List[Dict[str, Label]] = [{}]  # Local labels in the current memory scope
        self.global_labels = self.local_labels[0]  # Global memory labels
        self.ORG = org  # last ORG value set
        self.scopes: List[int] = []
        self.clear_temporary_labels()

        # Origins of code for asm mnemonics.
        # This will store corresponding asm instructions
        self.orgs: Dict[int, List[Asm]] = {}

    def enter_proc(self, lineno: int):
        """Enters (pushes) a new context"""
        self.local_labels.append({})  # Add a new context
        self.scopes.append(lineno)
        __DEBUG__("Entering scope level %i at line %i" % (len(self.scopes), lineno))

    def set_org(self, value: int, lineno: int):
        """Sets a new ORG value"""
        if value < 0 or value > self.MAX_MEM:
            error(lineno, "Memory ORG out of range [0 .. 65535]. Current value: %i" % value)

        self.clear_temporary_labels()
        self.index = self.ORG = value

    @staticmethod
    def id_name(label: str, namespace: Optional[str] = None) -> Tuple[str, str]:
        """Given a name and a namespace, resolves
        returns the name as namespace + '.' + name. If namespace
        is none, the current NAMESPACE is used
        """
        if namespace is None:
            namespace = asm_gl.NAMESPACE

        # temporary labels are just integer numbers
        if label.isdecimal() or label[-1] in "BF" and label[:-1].isdecimal():
            return label, namespace

        if not label.startswith(DOT):
            ex_label = asm_gl.normalize_namespace(f"{namespace}{DOT}{label}")  # The mangled namespace.labelname label
            return ex_label, namespace

        return label, namespace

    @property
    def org(self) -> int:
        """Returns current ORG index"""
        return self.index

    def __set_byte(self, byte: int, lineno: int):
        """Sets a byte at the current location,
        and increments org in one. Raises an error if org > MAX_MEMORY
        """
        if byte < 0 or byte > 255:
            error(lineno, "Invalid byte value %i" % byte)

        self.memory_bytes[self.org] = byte
        self.index += 1  # Increment current memory pointer

    def exit_proc(self, lineno: int):
        """Exits current procedure. Local labels are transferred to global
        scope unless they have been marked as local ones.
        Temporary labels are "forgotten", and used ones must be resolved at this point.

        Raises an error if no current local context (stack underflow)
        """
        __DEBUG__("Exiting current scope from lineno %i" % lineno)

        if len(self.local_labels) <= 1:
            error(lineno, "ENDP in global scope (with no PROC)")
            return

        for label in self.local_labels[-1].values():
            if label.local:
                if not label.defined:
                    error(lineno, "Undefined LOCAL label '%s'" % label.name)
                    return
                continue

            name = label.name
            _lineno = label.lineno
            value = label.value

            if name not in self.global_labels.keys():
                self.global_labels[name] = label
            else:
                self.global_labels[name].define(value, _lineno)

        self.local_labels.pop()  # Removes current context
        self.scopes.pop()

    def set_memory_slot(self):
        if self.org not in self.orgs:
            self.orgs[self.org] = []  # Declares an empty memory slot if not already done
            self.memory_bytes[self.org] = 0  # Declares an empty memory slot if not already done

    def resolve_temporary_label(self, fname: str, label: Label):
        if label.direction == -1:
            idx = bisect_right(self._tmp_labels_lines[fname], label.lineno)
            for line in self._tmp_labels_lines[fname][:idx][::-1]:
                if label == self._tmp_labels[(fname, line)].get(label.name):
                    label.value = self._tmp_labels[(fname, line)][label.name].value
                    return
        elif label.direction == +1:
            idx = bisect_left(self._tmp_labels_lines[fname], label.lineno)
            for line in self._tmp_labels_lines[fname][idx:]:
                if label == self._tmp_labels[(fname, line)].get(label.name):
                    label.value = self._tmp_labels[(fname, line)][label.name].value
                    return

    def clear_temporary_labels(self):
        self._tmp_labels_lines = defaultdict(list)
        self._tmp_labels = defaultdict(dict)
        self._tmp_pending_labels = defaultdict(list)

    def add_instruction(self, instr: Asm):
        """This will insert an asm instruction at the current memory position
        in a t-uple as (mnemonic, params).

        It will also insert the opcodes at the memory_bytes
        """
        if gl.has_errors:
            return

        __DEBUG__("%04Xh [%04Xh] ASM: %s" % (self.org, self.org - self.ORG, instr.asm))
        self.set_memory_slot()
        self.orgs[self.org].append(instr)

        for byte in instr.bytes():
            self.__set_byte(byte, instr.lineno)

    def dump(self):
        """Returns a tuple containing code ORG (origin address), and a list of bytes (OUTPUT)"""
        org = min(self.memory_bytes.keys())  # Org is the lowest one
        OUTPUT = []
        align = []

        for filename in self._tmp_pending_labels:
            for label in self._tmp_pending_labels[filename]:
                self.resolve_temporary_label(filename, label)
                if not label.defined:
                    error(label.lineno, "Undefined temporary label '%s'" % label.name)

        for label in self.global_labels.values():
            if not label.defined:
                error(label.lineno, "Undefined GLOBAL label '%s'" % label.name)

        for i in range(org, max(self.memory_bytes.keys()) + 1):
            if gl.has_errors:
                return org, OUTPUT

            try:
                try:
                    a = [x for x in self.orgs[i] if isinstance(x, Asm)]  # search for asm instructions

                    if not a:
                        align.append(0)  # Fill with ZEROes not used memory regions
                        continue

                    OUTPUT += align
                    align = []
                    a = a[0]
                    if a.pending:
                        a.arg = a.argval()
                        a.pending = False
                        tmp = a.bytes()

                        for r in range(len(tmp)):
                            self.memory_bytes[i + r] = tmp[r]
                except KeyError:
                    pass

                OUTPUT.append(self.memory_bytes[i])

            except KeyError:
                OUTPUT.append(0)  # Fill with ZEROes not used memory regions

        return org, OUTPUT

    def declare_label(
        self, label: str, lineno: int, value: int = None, local: bool = False, namespace: Optional[str] = None
    ) -> None:
        """Sets a label with the given value or with the current address (org)
        if no value is passed.

        Exits with error if label already set, otherwise return the label object
        """
        ex_label, namespace = Memory.id_name(label, namespace)

        is_address = value is None
        if value is None:
            value = self.org

        if is_address:
            __DEBUG__(f"Declaring '{ex_label}' (value {'%04Xh' % value}) in {lineno}")
        else:
            __DEBUG__(f"Declaring '{ex_label}' in {lineno}")

        fname = gl.FILENAME
        if label.isdecimal():  # Temporary label?
            assert (
                not self._tmp_labels_lines[fname] or self._tmp_labels_lines[fname][-1] <= lineno
            ), "Temporary label out of order"
            if not self._tmp_labels_lines[fname] or self._tmp_labels_lines[fname][-1] != lineno:
                self._tmp_labels_lines[fname].append(lineno)

            self._tmp_labels[(fname, lineno)][ex_label] = Label(
                ex_label, lineno, value, False, namespace, is_address=True
            )
            return

        if ex_label in self.local_labels[-1].keys():
            self.local_labels[-1][ex_label].define(value, lineno)
            self.local_labels[-1][ex_label].is_address = is_address
        else:
            self.local_labels[-1][ex_label] = Label(ex_label, lineno, value, local, namespace, is_address)

        self.set_memory_slot()

    def get_label(self, label: str, lineno: int) -> Label:
        """Returns a label in the current context or in the global one.
        If the label does not exist, creates a new one and returns it.
        """

        ex_label, namespace = Memory.id_name(label)
        result = Label(ex_label, lineno, namespace=namespace)

        if result.is_temporary:
            self._tmp_pending_labels[gl.FILENAME].append(result)
            return result

        for local_label in self.local_labels[::-1]:
            lbl = local_label.get(ex_label)
            if lbl is not None:
                return lbl

        self.local_labels[-1][ex_label] = result  # HINT: no namespace

        return result

    def set_label(self, label: str, lineno: int, local: bool = False) -> Label:
        """Sets a label, lineno and local flag in the current scope
        (even if it exists in previous scopes). If the label exist in
        the current scope, changes it flags.

        The resulting label is returned.
        """
        ex_label, namespace = Memory.id_name(label)

        if ex_label in self.local_labels[-1].keys():
            result = self.local_labels[-1][ex_label]
            result.lineno = lineno
        else:
            result = self.local_labels[-1][ex_label] = Label(ex_label, lineno, namespace=asm_gl.NAMESPACE)

        if result.local == local:
            warning(lineno, "label '%s' already declared as LOCAL" % label)

        result.local = local

        return result

    @property
    def memory_map(self) -> str:
        """Returns a (very long) string containing a memory map
        hex address: label
        """
        return "\n".join(sorted("%04X: %s" % (x.value, x.name) for x in self.global_labels.values() if x.is_address))
