from src.api.constants import SCOPE
from src.arch.z80.visitor.translator_visitor import TranslatorVisitor


class UnaryOpTranslator(TranslatorVisitor):
    """UNARY sub-visitor. E.g. -a or bNot pi"""

    def visit_MINUS(self, node):
        yield node.operand
        self.ic_neg(node.type_, node.t, node.operand.t)

    def visit_NOT(self, node):
        yield node.operand
        self.ic_not(node.operand.type_, node.t, node.operand.t)

    def visit_BNOT(self, node):
        yield node.operand
        self.ic_bnot(node.operand.type_, node.t, node.operand.t)

    def visit_ADDRESS(self, node):
        scope = node.operand.scope
        if node.operand.token == "ARRAYACCESS":
            yield node.operand
            # Address of an array element.
            if scope == SCOPE.global_:
                self.ic_aaddr(node.t, node.operand.entry.mangled)
            elif scope == SCOPE.parameter:
                self.ic_paaddr(node.t, f"*{node.operand.entry.offset}")
            elif scope == SCOPE.local:
                self.ic_paaddr(node.t, -node.operand.entry.offset)
        else:  # It's a scalar variable
            if scope == SCOPE.global_:
                self.ic_load(node.type_, node.t, "#" + node.operand.t)
            elif scope == SCOPE.parameter:
                self.ic_paddr(node.operand.offset + node.operand.type_.size % 2, node.t)
            elif scope == SCOPE.local:
                self.ic_paddr(-node.operand.offset, node.t)
