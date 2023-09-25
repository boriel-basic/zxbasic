# -*- coding: utf-8 -*-

from typing import List, NamedTuple

import src.api.global_ as gl
from src.api import string_labels
from src.api.config import OPTIONS
from src.api.constants import SCOPE, TYPE
from src.api.debug import __DEBUG__
from src.api.errmsg import syntax_error_cant_convert_to_type, syntax_error_not_constant
from src.api.exception import InvalidCONSTexpr, InvalidOperatorError
from src.arch.z80 import backend
from src.arch.z80.backend.runtime import LABEL_REQUIRED_MODULES, RUNTIME_LABELS
from src.arch.z80.backend.runtime import Labels as RuntimeLabel
from src.ast.tree import ChildrenList
from src.symbols import sym as symbols
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import Type

from .translator_inst_visitor import TranslatorInstVisitor


class JumpTable(NamedTuple):
    label: str
    addresses: ChildrenList


class TranslatorVisitor(TranslatorInstVisitor):
    """This visitor just adds the emit() method."""

    # ------------------------------------------------
    # A list of tokens that belongs to temporary
    # ATTR setting
    # ------------------------------------------------
    ATTR = ("INK", "PAPER", "BRIGHT", "FLASH", "OVER", "INVERSE", "BOLD", "ITALIC")
    ATTR_TMP = tuple(x + "_TMP" for x in ATTR)

    # Local flags
    HAS_ATTR = False

    # Previous Token
    PREV_TOKEN = None

    # Current Token
    CURR_TOKEN = None

    LOOPS = []  # Defined LOOPS
    JUMP_TABLES: List[JumpTable] = []

    # Type code used in DATA
    DATA_TYPES = {"str": 1, "i8": 2, "u8": 3, "i16": 4, "u16": 5, "i32": 6, "u32": 7, "f16": 8, "f": 9}

    @classmethod
    def reset(cls):
        cls.LOOPS.clear()  # Defined LOOPS
        cls.JUMP_TABLES.clear()
        string_labels.reset()

    def add_string_label(self, str_: str) -> str:
        """Maps ("folds") the given string, returning an unique label ID.
        This allows several constant labels to be initialized to the same address
        thus saving memory space.
        :param str_: the string to map
        :return: the unique label ID
        """
        return string_labels.add_string_label(str_)

    @property
    def O_LEVEL(self):
        return OPTIONS.optimization_level

    @staticmethod
    def TYPE(type_):
        """Converts a backend type (from api.constants)
        to a SymbolTYPE object (taken from the SYMBOL_TABLE).
        If type_ is already a SymbolTYPE object, nothing
        is done.
        """
        if isinstance(type_, symbols.TYPE):
            return type_

        assert TYPE.is_valid(type_)
        return gl.SYMBOL_TABLE.basic_types[type_]

    @staticmethod
    def dumpMemory(MEMORY):
        """Returns a sequence of Quads"""
        for x in MEMORY:
            yield str(x)

    # Generic Visitor methods
    def visit_BLOCK(self, node):
        __DEBUG__("BLOCK", 2)
        for child in node.children:
            yield child

    # Visits any temporal attribute
    def visit_ATTR_TMP(self, node):
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)

        label = {
            "INK_TMP": RuntimeLabel.INK_TMP,
            "PAPER_TMP": RuntimeLabel.PAPER_TMP,
            "FLASH_TMP": RuntimeLabel.FLASH_TMP,
            "BRIGHT_TMP": RuntimeLabel.BRIGHT_TMP,
            "INVERSE_TMP": RuntimeLabel.INVERSE_TMP,
            "OVER_TMP": RuntimeLabel.OVER_TMP,
            "BOLD_TMP": RuntimeLabel.BOLD_TMP,
            "ITALIC_TMP": RuntimeLabel.ITALIC_TMP,
        }[node.token]
        self.runtime_call(label, 0)  # Procedure call. Discard return

    def runtime_call(self, label: str, num: int):
        assert label in RUNTIME_LABELS, f"Unknown label {label}"
        super().ic_call(label, num)
        if label in LABEL_REQUIRED_MODULES:
            backend.REQUIRES.add(LABEL_REQUIRED_MODULES[label])

    # This function must be called before emit_strings
    def emit_data_blocks(self):
        if not gl.DATA_IS_USED:
            return  # nothing to do

        for label_, datas in gl.DATAS:
            self.ic_label(label_)
            for d in datas:
                if isinstance(d, symbols.FUNCDECL):
                    type_ = "%02Xh" % (self.DATA_TYPES[self.TSUFFIX(d.type_)] | 0x80)
                    self.ic_data(TYPE.byte, [type_])
                    self.ic_data(gl.PTR_TYPE, [d.mangled])
                    continue

                self.ic_data(TYPE.byte, [self.DATA_TYPES[self.TSUFFIX(d.value.type_)]])
                if d.value.type_ == self.TYPE(TYPE.string):
                    lbl = self.add_string_label(d.value.value)
                    self.ic_data(gl.PTR_TYPE, [lbl])
                elif d.value.type_ == self.TYPE(TYPE.fixed):  # Convert to bytes
                    bytes_ = 0xFFFFFFFF & int(d.value.value * 2**16)
                    self.ic_data(TYPE.uinteger, ["0x%04X" % (bytes_ & 0xFFFF), "0x%04X" % (bytes_ >> 16)])
                else:
                    self.ic_data(d.value.type_, [self.traverse_const(d.value)])

        if not gl.DATAS:  # The above loop was not executed, because there's no data
            self.ic_label("__DATA__0")
        else:
            missing_data_labels = set(gl.DATA_LABELS_REQUIRED).difference([x.label.name for x in gl.DATAS])
            for data_label in missing_data_labels:
                self.ic_label(data_label)  # A label reference by a RESTORE beyond the last DATA line

        self.ic_vard("__DATA__END", ["00"])

    def emit_strings(self):
        for str_, label_ in string_labels.STRING_LABELS.items():
            l = "%04X" % (len(str_) & 0xFFFF)  # TODO: Universalize for any arch
            self.ic_vard(label_, [l] + ["%02X" % ord(x) for x in str_])

    def emit_jump_tables(self):
        for table_ in self.JUMP_TABLES:
            self.ic_vard(
                table_.label, [f"#{str(len(table_.addresses))}"] + [f"##{x.mangled}" for x in table_.addresses]
            )

    def _visit(self, node):
        if isinstance(node, Symbol):
            __DEBUG__(f"Visiting {node.token}", 1)
            if node.token in self.ATTR_TMP:
                return self.visit_ATTR_TMP(node)

        return TranslatorInstVisitor._visit(self, node)

    def norm_attr(self):
        """Normalize attr state"""
        self.runtime_call(RuntimeLabel.COPY_ATTR, 0)

    @staticmethod
    def traverse_const(node):
        """Traverses a constant and returns a string
        with the arithmetic expression
        """
        if node.token == "NUMBER":
            return node.t

        if node.token == "CONST":
            return node.t

        if node.token == "UNARY":
            mid = node.operator
            if mid == "MINUS":
                result = " -" + TranslatorVisitor.traverse_const(node.operand)
            elif mid == "ADDRESS":
                if node.operand.scope == SCOPE.global_ or node.operand.token in ("LABEL", "FUNCTION"):
                    result = TranslatorVisitor.traverse_const(node.operand)
                else:
                    syntax_error_not_constant(node.operand.lineno)
                    return
            else:
                raise InvalidOperatorError(mid)
            return result

        if node.token == "BINARY":
            operator = {
                "PLUS": "+",
                "MINUS": "-",
                "MUL": "*",
                "DIV": "/",
                "MOD": "%",
                "POW": "^",
                "SHL": ">>",
                "SHR": "<<",
            }

            mid = operator.get(node.operator)
            if mid is None:
                raise InvalidOperatorError(node.operator)

            return "(%s) %s (%s)" % (
                TranslatorVisitor.traverse_const(node.left),
                mid,
                TranslatorVisitor.traverse_const(node.right),
            )

        if node.token == "TYPECAST":
            if node.type_ in (Type.byte_, Type.ubyte):
                return "(" + TranslatorVisitor.traverse_const(node.operand) + ") & 0xFF"
            if node.type_ in (Type.integer, Type.uinteger):
                return "(" + TranslatorVisitor.traverse_const(node.operand) + ") & 0xFFFF"
            if node.type_ in (Type.long_, Type.ulong):
                return "(" + TranslatorVisitor.traverse_const(node.operand) + ") & 0xFFFFFFFF"
            if node.type_ == Type.fixed:
                return "((" + TranslatorVisitor.traverse_const(node.operand) + ") & 0xFFFF) << 16"
            syntax_error_cant_convert_to_type(node.lineno, str(node.operand), node.type_)
            return

        if node.token == "VARARRAY":
            return node.data_label

        if node.token in ("CONST", "VAR", "LABEL", "FUNCTION"):
            # TODO: Check what happens with local vars and params
            return node.t

        if node.token == "CONSTEXPR":
            return TranslatorVisitor.traverse_const(node.expr)

        if node.token == "ARRAYACCESS":
            return "({} + {})".format(node.entry.data_label, node.offset)

        if node.token == "ID" and node.has_address and node.scope == SCOPE.global_:
            return node.mangled

        raise InvalidCONSTexpr(node)

    @staticmethod
    def check_attr(node, n):
        """Check if ATTR has to be normalized
        after this instruction has been translated
        to intermediate code.
        """
        if len(node.children) > n:
            return node.children[n]
