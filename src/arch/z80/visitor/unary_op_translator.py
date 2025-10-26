# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

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
        """Emits the code to compute the address of a variable."""
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
            else:
                raise Exception("Invalid scope")
            return

        self.emit_variable_addr(node.operand)
