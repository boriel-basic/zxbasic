import src.api
from src.api import global_ as gl
from src.api.config import OPTIONS
from src.api.constants import CLASS, CONVENTION, SCOPE, TYPE
from src.api.debug import __DEBUG__
from src.api.global_ import optemps
from src.arch.z80 import backend
from src.arch.z80.backend.runtime import Labels as RuntimeLabel
from src.arch.z80.visitor.translator import LabelledData
from src.arch.zx48k.backend import Backend
from src.symbols import sym as symbols

from .translator import Translator


class FunctionTranslator(Translator):
    REQUIRES = backend.REQUIRES

    def __init__(self, backend: Backend, function_list: list[symbols.ID]):
        if function_list is None:
            function_list = []
        super().__init__(backend)

        assert isinstance(function_list, list)
        assert all(x.token == "FUNCTION" for x in function_list)
        self.functions = function_list

    def _local_array_load(self, scope, local_var):
        t2 = optemps.new_t()
        if scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, t2, "%i" % (local_var.offset - self.TYPE(gl.PTR_TYPE).size))
        elif scope == SCOPE.local:
            self.ic_pload(gl.PTR_TYPE, t2, "%i" % -(local_var.offset - self.TYPE(gl.PTR_TYPE).size))
        self.ic_fparam(gl.PTR_TYPE, t2)

    def start(self):
        while self.functions:
            f = self.functions.pop(0)
            __DEBUG__("Translating function " + f.__repr__())
            self.visit(f)

    def visit_FUNCTION(self, node):
        bound_tables = []

        self.ic_label(node.mangled)
        if node.convention == CONVENTION.fastcall:
            self.ic_enter("__fastcall__")
        else:
            self.ic_enter(node.locals_size)

        for local_var in node.local_symbol_table.values():
            if not local_var.accessed:  # HINT: This should never happen as values() is already filtered
                src.api.errmsg.warning_not_used(local_var.lineno, local_var.name)
                # HINT: Cannot optimize local variables now, since the offsets are already calculated
                # if self.O_LEVEL > 1:
                #    return

            if local_var.class_ == CLASS.const or local_var.scope == SCOPE.parameter:
                continue

            if local_var.class_ == CLASS.array and local_var.scope == SCOPE.local:
                lbound_label = local_var.mangled + ".__LBOUND__"
                ubound_label = local_var.mangled + ".__UBOUND__"
                lbound_needed = not local_var.is_zero_based and local_var.is_dynamically_accessed

                bound_ptrs = [lbound_label if lbound_needed else "0", "0"]
                if local_var.ubound_used:
                    bound_ptrs[1] = ubound_label

                if bound_ptrs != ["0", "0"]:
                    OPTIONS["__DEFINES"].value["__ZXB_USE_LOCAL_ARRAY_WITH_BOUNDS__"] = ""

                if lbound_needed:
                    l = ["%04X" % bound.lower for bound in local_var.bounds]
                    bound_tables.append(LabelledData(lbound_label, l))

                if local_var.ubound_used:
                    l = ["%04X" % bound.upper for bound in local_var.bounds]
                    bound_tables.append(LabelledData(ubound_label, l))

                l = [len(local_var.bounds) - 1] + [x.count for x in local_var.bounds[1:]]  # TODO Check this
                q = []
                for x in l:
                    q.append("%02X" % (x & 0xFF))
                    q.append("%02X" % ((x & 0xFF) >> 8))

                q.append("%02X" % local_var.type_.size)
                r = []
                if local_var.default_value is not None:
                    r.extend(self.array_default_value(local_var.type_, local_var.default_value))
                self.ic_larrd(local_var.offset, q, local_var.size, r, bound_ptrs)  # Initializes array bounds

            else:  # Local vars always defaults to 0, so if 0 we do nothing
                if (
                    local_var.token != "FUNCTION"
                    and local_var.default_value is not None
                    and local_var.default_value != 0
                ):
                    if (
                        isinstance(local_var.default_value, symbols.CONSTEXPR)
                        and local_var.default_value.token == "CONSTEXPR"
                    ):
                        self.ic_lvarx(local_var.type_, local_var.offset, [self.traverse_const(local_var.default_value)])
                    else:
                        q = self.default_value(local_var.type_, local_var.default_value)
                        self.ic_lvard(local_var.offset, q)

        for i in node.ref.body:
            yield i

        self.ic_label("%s__leave" % node.mangled)

        # Now free any local string from memory.
        preserve_hl = False
        if node.convention == CONVENTION.stdcall:
            for local_var in node.local_symbol_table.values():
                scope = local_var.scope
                if local_var.type_ == self.TYPE(TYPE.string):
                    if local_var.class_ == CLASS.const or local_var.token == "FUNCTION":
                        continue

                    # Only if it's string we free it
                    if local_var.class_ != CLASS.array:  # Ok just free it
                        if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                            if not preserve_hl:
                                preserve_hl = True
                                self.ic_exchg()

                            offset = -local_var.offset if scope == SCOPE.local else local_var.offset
                            self.ic_fpload(TYPE.string, local_var.t, offset)
                            self.runtime_call(RuntimeLabel.MEM_FREE, 0)
                    else:  # This is an array of strings, we must free it unless it's a by_ref array
                        if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                            if not preserve_hl:
                                preserve_hl = True
                                self.ic_exchg()

                            self.ic_param(gl.BOUND_TYPE, local_var.count)
                            self._local_array_load(scope, local_var)
                            self.runtime_call(RuntimeLabel.ARRAYSTR_FREE_MEM, 0)

                if (
                    local_var.class_ == CLASS.array
                    and local_var.type_ != self.TYPE(TYPE.string)
                    and (scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref))
                ):
                    if not preserve_hl:
                        preserve_hl = True
                        self.ic_exchg()

                    self._local_array_load(scope, local_var)
                    self.runtime_call(RuntimeLabel.MEM_FREE, 0)

        if preserve_hl:
            self.ic_exchg()

        if node.convention == CONVENTION.fastcall:
            self.ic_leave(CONVENTION.to_string(node.convention))
        else:
            self.ic_leave(node.ref.params.size)

        for bound_table in bound_tables:
            self.ic_vard(bound_table.label, bound_table.data)

    def visit_FUNCDECL(self, node):
        """Nested scope functions"""
        self.functions.append(node.entry)
