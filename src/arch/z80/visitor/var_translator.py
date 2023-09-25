import src.api
from src.api import global_ as gl
from src.arch.z80 import Translator
from src.arch.z80.visitor.translator_visitor import TranslatorVisitor
from src.symbols import sym as symbols


class VarTranslator(TranslatorVisitor):
    """Var Translator
    This translator emits memory var space
    """

    def visit_LABEL(self, node):
        self.ic_label(node.mangled)
        for tmp in node.aliased_by:
            self.ic_label(tmp.mangled)

    def visit_VARDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            src.api.errmsg.warning_not_used(entry.lineno, entry.name, fname=entry.filename)
            if self.O_LEVEL > 1:  # HINT: Unused vars not compiled
                return

        if entry.addr is not None:
            addr = self.traverse_const(entry.addr) if isinstance(entry.addr, symbols.SYMBOL) else entry.addr
            self.ic_deflabel(entry.mangled, addr)
        else:
            if entry.default_value is None:
                self.ic_var(entry.mangled, entry.size)
            else:
                if entry.default_value.token == "CONSTEXPR":
                    self.ic_varx(node.mangled, node.type_, [self.traverse_const(entry.default_value)])
                else:
                    self.ic_vard(node.mangled, Translator.default_value(node.type_, entry.default_value))

    def visit_ARRAYDECL(self, node):
        entry = node.entry
        assert entry.default_value is None or entry.addr is None, "Cannot use address and default_value at once"

        if not entry.accessed:
            src.api.errmsg.warning_not_used(entry.lineno, entry.name, fname=entry.filename)
            if self.O_LEVEL > 1:
                return

        bound_ptrs = []  # Bound tables pointers (empty if not used)
        lbound_label = entry.mangled + ".__LBOUND__"
        ubound_label = entry.mangled + ".__UBOUND__"

        if entry.lbound_used or entry.ubound_used:
            bound_ptrs = ["0", "0"]  # NULL by default
            if entry.lbound_used:
                bound_ptrs[0] = lbound_label
            if entry.ubound_used:
                bound_ptrs[1] = ubound_label

        data_label = entry.data_label
        idx_table_label = src.api.tmp_labels.tmp_label()
        l = ["%04X" % (len(node.bounds) - 1)]  # Number of dimensions - 1

        for bound in node.bounds[1:]:
            l.append("%04X" % (bound.upper - bound.lower + 1))

        l.append("%02X" % node.type_.size)
        arr_data = []

        if entry.addr:
            addr = self.traverse_const(entry.addr) if isinstance(entry.addr, symbols.SYMBOL) else entry.addr
            self.ic_deflabel(data_label, "%s" % addr)
        else:
            if entry.default_value is not None:
                arr_data = Translator.array_default_value(node.type_, entry.default_value)
            else:
                arr_data = ["00"] * node.size

        self.ic_varx(node.mangled, gl.PTR_TYPE, [idx_table_label])

        if entry.addr:
            self.ic_varx(entry.data_ptr_label, gl.PTR_TYPE, [self.traverse_const(entry.addr)])
            if bound_ptrs:
                self.ic_data(gl.PTR_TYPE, bound_ptrs)
        else:
            self.ic_varx(entry.data_ptr_label, gl.PTR_TYPE, [data_label])
            if bound_ptrs:
                self.ic_data(gl.PTR_TYPE, bound_ptrs)
            self.ic_vard(data_label, arr_data)

        self.ic_vard(idx_table_label, l)

        if entry.lbound_used:
            l = ["%04X" % bound.lower for bound in node.bounds]
            self.ic_vard(lbound_label, l)

        if entry.ubound_used:
            l = ["%04X" % bound.upper for bound in node.bounds]
            self.ic_vard(ubound_label, l)
