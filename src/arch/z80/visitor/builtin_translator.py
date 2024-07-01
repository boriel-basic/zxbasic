from src.api import global_ as gl
from src.api.constants import SCOPE, TYPE
from src.api.global_ import optemps
from src.arch.z80 import backend
from src.arch.z80.backend.runtime import Labels as RuntimeLabel
from src.arch.z80.visitor.translator_visitor import TranslatorVisitor
from src.symbols.type_ import Type


class BuiltinTranslator(TranslatorVisitor):
    """BUILTIN functions visitor. Eg. LEN(a$) or SIN(x)"""

    REQUIRES = backend.REQUIRES

    # region STRING Functions
    def visit_INKEY(self, node):
        self.runtime_call(RuntimeLabel.INKEY, Type.string.size)

    def visit_IN(self, node):
        self.ic_in(node.children[0].t)

    def visit_CODE(self, node):
        self.ic_fparam(gl.PTR_TYPE, node.operand.t)
        if node.operand.token not in ("STRING", "VAR") and node.operand.t != "_":
            self.ic_fparam(TYPE.ubyte, 1)  # If the argument is not a variable, it must be freed
        else:
            self.ic_fparam(TYPE.ubyte, 0)

        self.runtime_call(RuntimeLabel.ASC, Type.ubyte.size)  # Expect a char code

    def visit_CHR(self, node):
        self.ic_fparam(gl.STR_INDEX_TYPE, len(node.operand))  # Number of args
        self.runtime_call(RuntimeLabel.CHR, node.size)

    def visit_STR(self, node):
        self.ic_fparam(TYPE.float, node.children[0].t)
        self.runtime_call(RuntimeLabel.STR_FAST, node.type_.size)

    def visit_LEN(self, node):
        self.ic_lenstr(node.t, node.operand.t)

    def visit_VAL(self, node):
        self.ic_fparam(gl.PTR_TYPE, node.operand.t)
        if node.operand.token not in ("STRING", "VAR") and node.operand.t != "_":
            self.ic_fparam(TYPE.ubyte, 1)  # If the argument is not a variable, it must be freed
        else:
            self.ic_fparam(TYPE.ubyte, 0)

        self.runtime_call(RuntimeLabel.VAL, node.type_.size)

    # endregion

    def visit_ABS(self, node):
        self.ic_abs(node.children[0].type_, node.t, node.children[0].t)

    def visit_RND(self, node):  # A special "ZEROARY" function with no parameters
        self.runtime_call(RuntimeLabel.RND, Type.float_.size)

    def visit_PEEK(self, node):
        if node.operand.token == "NUMBER":
            self.ic_load(node.type_, node.t, "*#" + str(node.operand.t))
        else:
            self.ic_load(node.type_, node.t, "*" + str(node.operand.t))

    # region MATH Functions
    def visit_SIN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.SIN, node.size)

    def visit_COS(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.COS, node.size)

    def visit_TAN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.TAN, node.size)

    def visit_ASN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ASN, node.size)

    def visit_ACS(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ACS, node.size)

    def visit_ATN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ATN, node.size)

    def visit_EXP(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.EXP, node.size)

    def visit_LN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.LN, node.size)

    def visit_SGN(self, node):
        s = self.TSUFFIX(node.operand.type_)
        self.ic_fparam(node.operand.type_, node.operand.t)

        label = {
            "i8": RuntimeLabel.SGNI8,
            "u8": RuntimeLabel.SGNU8,
            "i16": RuntimeLabel.SGNI16,
            "u16": RuntimeLabel.SGNU16,
            "i32": RuntimeLabel.SGNI32,
            "u32": RuntimeLabel.SGNU32,
            "f16": RuntimeLabel.SGNF16,
            "f": RuntimeLabel.SGNF,
        }[s]
        self.runtime_call(label, node.size)

    def visit_SQR(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.SQR, node.size)

    # endregion

    def visit_LBOUND(self, node):
        yield node.operands[1]
        self.ic_param(gl.BOUND_TYPE, node.operands[1].t)
        entry = node.operands[0]
        if entry.scope == SCOPE.global_:
            self.ic_fparam(gl.PTR_TYPE, f"#{entry.mangled}")
        elif entry.scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, entry.t, entry.offset)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        elif entry.scope == SCOPE.local:
            self.ic_paddr(-entry.offset, entry.t)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        self.runtime_call(RuntimeLabel.LBOUND, self.TYPE(gl.BOUND_TYPE).size)

    def visit_UBOUND(self, node):
        yield node.operands[1]
        self.ic_param(gl.BOUND_TYPE, node.operands[1].t)
        entry = node.operands[0]
        if entry.scope == SCOPE.global_:
            self.ic_fparam(gl.PTR_TYPE, f"#{entry.mangled}")
        elif entry.scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, entry.t, entry.offset)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        elif entry.scope == SCOPE.local:
            self.ic_paddr(-entry.offset, entry.t)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        self.runtime_call(RuntimeLabel.UBOUND, self.TYPE(gl.BOUND_TYPE).size)

    def visit_USR_STR(self, node):
        # USR ADDR
        self.ic_fparam(TYPE.string, node.children[0].t)
        self.runtime_call(RuntimeLabel.USR_STR, node.type_.size)

    def visit_USR(self, node):
        """Machine code call from basic"""
        self.ic_fparam(gl.PTR_TYPE, node.children[0].t)
        self.runtime_call(RuntimeLabel.USR, node.type_.size)
